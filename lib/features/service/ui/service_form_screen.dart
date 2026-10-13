import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../core/service_calculator.dart';
import '../../../core/vehicle_components.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../providers/service_providers.dart';

class _PartEntry {
  _PartEntry({String name = '', String brand = ''})
      : nameController = TextEditingController(text: name),
        brandController = TextEditingController(text: brand);

  final TextEditingController nameController;
  final TextEditingController brandController;
  String? errorText;

  void dispose() {
    nameController.dispose();
    brandController.dispose();
  }
}

/// Layar Form Tambah Catatan Servis Multi-Item
/// Mengacu pada docs/design/form_pencatatan_mandiri_motor/ dan docs/SPEC.md (F5 revisi v2.2)
class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({
    super.key,
    this.vehicleId,
    this.initialComponentType,
    this.onSavedSuccess,
  });

  /// ID kendaraan opsional (default menggunakan active/selected vehicle)
  final String? vehicleId;

  /// Tipe komponen yang dipilih awal (misal saat kartu komponen ditekan di dashboard)
  final String? initialComponentType;

  /// Callback opsional setelah berhasil disimpan
  final VoidCallback? onSavedSuccess;

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  late TextEditingController _kmController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _noteController;

  // Komponen Standar (Matic)
  bool _isEngineOilSelected = false;
  late TextEditingController _engineOilBrandController;

  bool _isGearOilSelected = false;
  late TextEditingController _gearOilBrandController;

  bool _isVBeltSelected = false;
  ServiceItemAction _vBeltAction = ServiceItemAction.replaced;
  late TextEditingController _vBeltBrandController;

  // Part Lain yang Diganti
  final List<_PartEntry> _partEntries = [];

  late DateTime _selectedDate;

  String? _kmError;
  String? _locationError;
  String? _priceError;
  String? _itemsError;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    _kmController = TextEditingController();
    _locationController = TextEditingController();
    _priceController = TextEditingController();
    _noteController = TextEditingController();

    _engineOilBrandController = TextEditingController();
    _gearOilBrandController = TextEditingController();
    _vBeltBrandController = TextEditingController();

    // Atur komponen yang dipilih awal berdasarkan initialComponentType
    final initType = widget.initialComponentType;
    if (initType == ComponentType.gearOil) {
      _isGearOilSelected = true;
    } else if (initType == ComponentType.vBelt) {
      _isVBeltSelected = true;
    } else {
      _isEngineOilSelected = true;
    }

    // Default KM saat ini akan diisi di post-frame callback jika belum diisi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeVehicle = _resolveVehicle();
      if (activeVehicle != null && _kmController.text.isEmpty) {
        _kmController.text = activeVehicle.currentKm.toString();
      }
    });
  }

  @override
  void dispose() {
    _kmController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _noteController.dispose();

    _engineOilBrandController.dispose();
    _gearOilBrandController.dispose();
    _vBeltBrandController.dispose();

    for (final entry in _partEntries) {
      entry.dispose();
    }

    super.dispose();
  }

  Vehicle? _resolveVehicle() {
    final vehicles = ref.read(vehiclesStreamProvider).asData?.value ?? [];
    if (widget.vehicleId != null) {
      final found = vehicles.where((v) => v.id == widget.vehicleId).firstOrNull;
      if (found != null) return found;
    }
    return ref.read(selectedVehicleProvider);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Servis',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addPartRow() {
    setState(() {
      _partEntries.add(_PartEntry());
      _itemsError = null;
    });
  }

  void _removePartRow(int index) {
    setState(() {
      final removed = _partEntries.removeAt(index);
      removed.dispose();
    });
  }

  bool _validateInputs() {
    String? kmErr;
    String? locErr;
    String? priceErr;
    String? itemsErr;

    final kmVal = _kmController.text.replaceAll('.', '').trim();
    if (kmVal.isEmpty) {
      kmErr = 'Kilometer servis wajib diisi';
    } else {
      final parsedKm = int.tryParse(kmVal);
      if (parsedKm == null || parsedKm < 0) {
        kmErr = 'Masukkan angka kilometer yang valid';
      }
    }

    if (_locationController.text.trim().isEmpty) {
      locErr = 'Nama bengkel atau tempat servis wajib diisi';
    }

    final priceVal = _priceController.text.trim();
    if (priceVal.isEmpty) {
      priceErr = 'Total biaya wajib diisi (ketik 0 jika gratis)';
    } else {
      final parsedPrice = ServiceCalculator.parseRupiahInput(priceVal);
      if (parsedPrice == null || parsedPrice < 0) {
        priceErr = 'Masukkan angka biaya yang valid (minimal 0)';
      }
    }

    // Validasi minimal 1 item
    final hasComponent = _isEngineOilSelected || _isGearOilSelected || _isVBeltSelected;
    final hasParts = _partEntries.isNotEmpty;

    if (!hasComponent && !hasParts) {
      itemsErr = 'Pilih minimal satu komponen atau tambahkan part lain';
    }

    // Validasi tiap baris part lain
    bool partValid = true;
    for (final entry in _partEntries) {
      if (entry.nameController.text.trim().isEmpty) {
        entry.errorText = 'Nama part wajib diisi';
        partValid = false;
      } else {
        entry.errorText = null;
      }
    }

    setState(() {
      _kmError = kmErr;
      _locationError = locErr;
      _priceError = priceErr;
      _itemsError = itemsErr;
    });

    return kmErr == null && locErr == null && priceErr == null && itemsErr == null && partValid;
  }

  List<ServiceItem> _buildServiceItems() {
    final items = <ServiceItem>[];

    if (_isEngineOilSelected) {
      items.add(
        ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.engineOil,
          action: ServiceItemAction.replaced,
          brand: _engineOilBrandController.text.trim().isNotEmpty
              ? _engineOilBrandController.text.trim()
              : null,
        ),
      );
    }

    if (_isGearOilSelected) {
      items.add(
        ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.gearOil,
          action: ServiceItemAction.replaced,
          brand: _gearOilBrandController.text.trim().isNotEmpty
              ? _gearOilBrandController.text.trim()
              : null,
        ),
      );
    }

    if (_isVBeltSelected) {
      items.add(
        ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.vBelt,
          action: _vBeltAction,
          brand: (_vBeltAction == ServiceItemAction.replaced &&
                  _vBeltBrandController.text.trim().isNotEmpty)
              ? _vBeltBrandController.text.trim()
              : null,
        ),
      );
    }

    for (final entry in _partEntries) {
      final name = entry.nameController.text.trim();
      final brand = entry.brandController.text.trim();
      if (name.isNotEmpty) {
        items.add(
          ServiceItem(
            kind: ServiceItemKind.part,
            name: name,
            action: ServiceItemAction.replaced,
            brand: brand.isNotEmpty ? brand : null,
          ),
        );
      }
    }

    return items;
  }

  Future<void> _saveService(Vehicle vehicle) async {
    if (!_validateInputs()) {
      return;
    }

    final km = int.parse(_kmController.text.replaceAll('.', '').trim());
    final price = ServiceCalculator.parseRupiahInput(_priceController.text)!;
    final items = _buildServiceItems();

    final success = await ref.read(serviceControllerProvider.notifier).addServiceRecord(
      vehicleId: vehicle.id,
      items: items,
      date: _selectedDate,
      km: km,
      price: price,
      location: _locationController.text.trim(),
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan servis tersimpan! Perhitungan status motor telah diperbarui.'),
          backgroundColor: AppColors.tertiary,
        ),
      );

      if (widget.onSavedSuccess != null) {
        widget.onSavedSuccess!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } else {
      final error = ref.read(serviceControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menyimpan catatan servis.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = _resolveVehicle();
    final controllerState = ref.watch(serviceControllerProvider);

    if (activeVehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Catat Servis'),
          backgroundColor: AppColors.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Symbols.two_wheeler, size: 56, color: AppColors.outline),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Belum ada motor yang dipilih',
                  style: AppTypography.headlineSm(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tambahkan motor terlebih dahulu untuk mencatat servis berkala.',
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'Tambah Motor',
                  onPressed: () => context.push('/vehicles/add'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form Catat Servis',
              style: AppTypography.headlineSm().copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              activeVehicle.displayName,
              style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Motor Aktif
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppShapes.roundedDefault,
                  border: Border.all(color: AppColors.borderSlate),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Symbols.two_wheeler,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOTOR AKTIF',
                            style: AppTypography.labelCaps(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activeVehicle.displayName} ${activeVehicle.plate != null ? "(${activeVehicle.plate})" : ""}',
                            style: AppTypography.bodyMd().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: AppShapes.roundedFull,
                      ),
                      child: Text(
                        'Odo: ${ServiceCalculator.formatKm(activeVehicle.currentKm)} KM',
                        style: AppTypography.labelCaps(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bagian 1: Komponen Utama (Matic)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'KOMPONEN UTAMA (MATIC)',
                          style: AppTypography.labelCaps(
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Pilih yang dikerjakan',
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Card 1: Oli Mesin
                  _buildComponentCard(
                    title: 'Oli Mesin',
                    icon: Symbols.oil_barrel,
                    isSelected: _isEngineOilSelected,
                    onToggle: (val) {
                      setState(() {
                        _isEngineOilSelected = val;
                        _itemsError = null;
                      });
                    },
                    actionBadge: 'Selalu Diganti',
                    brandController: _engineOilBrandController,
                    brandHint: 'Merek oli mesin (opsional, mis. SPX2, Shell)',
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Card 2: Oli Gardan
                  _buildComponentCard(
                    title: 'Oli Gardan',
                    icon: Symbols.water_drop,
                    isSelected: _isGearOilSelected,
                    onToggle: (val) {
                      setState(() {
                        _isGearOilSelected = val;
                        _itemsError = null;
                      });
                    },
                    actionBadge: 'Selalu Diganti',
                    brandController: _gearOilBrandController,
                    brandHint: 'Merek oli gardan (opsional, mis. AHM, Yamalube)',
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Card 3: V-Belt (Pilihan Diganti / Dibersihkan)
                  _buildVBeltCard(),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bagian 2: Part Lain yang Diganti (SPEC F5)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'PART LAIN YANG DIGANTI',
                          style: AppTypography.labelCaps(
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_partEntries.length} part',
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Suku cadang lain (mis. roller, kampas ganda, busi, filter udara, kampas rem). Part lain tercatat di riwayat tanpa mengubah kartu kesehatan.',
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (_partEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: AppShapes.roundedDefault,
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada part lain yang ditambahkan.',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ..._partEntries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildPartRow(index, item);
                    }),

                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _addPartRow,
                      icon: const Icon(Symbols.add_circle, size: 20),
                      label: const Text(
                        'Tambah Part Lain',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),

              if (_itemsError != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.4),
                    borderRadius: AppShapes.roundedDefault,
                  ),
                  child: Row(
                    children: [
                      const Icon(Symbols.error, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _itemsError!,
                          style: AppTypography.bodySm(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Input: Odometer Saat Servis (KM) + Tombol "Gunakan KM Terkini"
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'ODOMETER SAAT SERVIS (KM)',
                          style: AppTypography.labelCaps(
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: AppShapes.roundedFull,
                        onTap: () {
                          setState(() {
                            _kmController.text = activeVehicle.currentKm.toString();
                            _kmError = null;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.auto_fix_high,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Gunakan KM Terkini',
                              style: AppTypography.labelCaps(
                                color: AppColors.primary,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _kmController,
                    hintText: 'Misal: ${activeVehicle.currentKm}',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Symbols.speed, size: 20),
                    errorText: _kmError,
                    onChanged: (_) {
                      if (_kmError != null) setState(() => _kmError = null);
                    },
                    suffix: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Text(
                        'KM',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Input: Tanggal Servis
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TANGGAL SERVIS',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: AppShapes.roundedDefault,
                    onTap: _pickDate,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: AppShapes.roundedDefault,
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Symbols.calendar_month,
                            size: 20,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              ServiceCalculator.formatFullDate(_selectedDate),
                              style: AppTypography.bodyMd(),
                            ),
                          ),
                          const Icon(
                            Symbols.edit_calendar,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Input: Bengkel / Lokasi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAMA BENGKEL / TEMPAT PENGERJAAN',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _locationController,
                    hintText: 'Contoh: AHASS Mitra Jaya / Servis Mandiri',
                    prefixIcon: const Icon(Symbols.store, size: 20),
                    errorText: _locationError,
                    onChanged: (_) {
                      if (_locationError != null) setState(() => _locationError = null);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Input: Total Biaya Servis (1 kunjungan)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BIAYA SERVIS & SUKU CADANG (SATU KUNJUNGAN)',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _priceController,
                    hintText: '145.000 (ketik 0 jika gratis)',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, top: 14),
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    errorText: _priceError,
                    onChanged: (_) {
                      if (_priceError != null) setState(() => _priceError = null);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Input: Catatan Opsional
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATATAN MEKANIK / KELUHAN (OPSIONAL)',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _noteController,
                    hintText: 'Tuliskan saran mekanik atau indikasi bagian yang perlu dicek...',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Tombol Simpan
              AppButton(
                text: 'Simpan Catatan Servis',
                icon: const Icon(Symbols.check_circle, size: 20, color: AppColors.onPrimary),
                isLoading: controllerState.isLoading,
                onPressed: () => _saveService(activeVehicle),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required ValueChanged<bool> onToggle,
    required String actionBadge,
    required TextEditingController brandController,
    required String brandHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryContainer.withValues(alpha: 0.08)
            : AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderSlate,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                onChanged: (val) => onToggle(val ?? false),
              ),
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.outline),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMd().copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryFixed : AppColors.surfaceContainer,
                  borderRadius: AppShapes.roundedFull,
                ),
                child: Text(
                  actionBadge,
                  style: AppTypography.labelCaps(
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 8, bottom: 4),
              child: AppTextField(
                controller: brandController,
                hintText: brandHint,
                prefixIcon: const Icon(Symbols.sell, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVBeltCard() {
    final isSelected = _isVBeltSelected;
    final isReplaced = _vBeltAction == ServiceItemAction.replaced;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryContainer.withValues(alpha: 0.08)
            : AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderSlate,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _isVBeltSelected = val ?? false;
                    _itemsError = null;
                  });
                },
              ),
              Icon(
                Symbols.settings,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.outline,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'V-Belt (CVT)',
                  style: AppTypography.bodyMd().copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 8, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilihan Aksi: Diganti vs Dibersihkan (SPEC F5)
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: const Text('Diganti'),
                        selected: isReplaced,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isReplaced ? AppColors.onPrimary : AppColors.onSurface,
                          fontWeight: isReplaced ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _vBeltAction = ServiceItemAction.replaced);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Dibersihkan'),
                        selected: !isReplaced,
                        selectedColor: AppColors.tertiary,
                        labelStyle: TextStyle(
                          color: !isReplaced ? AppColors.onTertiary : AppColors.onSurface,
                          fontWeight: !isReplaced ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _vBeltAction = ServiceItemAction.cleaned);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReplaced
                        ? 'Kartu V-Belt akan di-reset (100% aman).'
                        : 'Hanya tercatat di riwayat, kartu V-Belt tidak di-reset.',
                    style: AppTypography.bodySm(
                      color: isReplaced ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (isReplaced) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _vBeltBrandController,
                      hintText: 'Merek V-Belt (opsional, mis. Bando, Mitsuboshi)',
                      prefixIcon: const Icon(Symbols.sell, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartRow(int index, _PartEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: entry.errorText != null ? AppColors.error : AppColors.borderSlate,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: entry.nameController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintText: 'Nama part (mis. Roller, Busi)',
                    hintStyle: AppTypography.bodySm(color: AppColors.outline),
                    border: OutlineInputBorder(
                      borderRadius: AppShapes.roundedDefault,
                      borderSide: const BorderSide(color: AppColors.borderSlate),
                    ),
                  ),
                  style: AppTypography.bodySm(),
                  onChanged: (_) {
                    if (entry.errorText != null) {
                      setState(() => entry.errorText = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry.brandController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintText: 'Merek (opsional)',
                    hintStyle: AppTypography.bodySm(color: AppColors.outline),
                    border: OutlineInputBorder(
                      borderRadius: AppShapes.roundedDefault,
                      borderSide: const BorderSide(color: AppColors.borderSlate),
                    ),
                  ),
                  style: AppTypography.bodySm(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Symbols.delete, size: 20, color: AppColors.error),
                tooltip: 'Hapus part',
                onPressed: () => _removePartRow(index),
              ),
            ],
          ),
          if (entry.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                entry.errorText!,
                style: AppTypography.labelCaps(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
