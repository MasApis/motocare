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

/// Layar Form Tambah Catatan Servis
/// Mengacu pada docs/design/form_pencatatan_mandiri_motor/ dan docs/SPEC.md (F5)
class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({
    super.key,
    this.vehicleId,
    this.initialComponentType,
    this.onSavedSuccess,
  });

  /// ID kendaraan opsional (default menggunakan active/selected vehicle)
  final String? vehicleId;

  /// Tipe komponen yang dipilih awal (misal saat kartu komponen ditekan)
  final String? initialComponentType;

  /// Callback opsional setelah berhasil disimpan
  final VoidCallback? onSavedSuccess;

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  late TextEditingController _kmController;
  late TextEditingController _brandController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _noteController;

  late String _selectedComponentType;
  late DateTime _selectedDate;

  String? _kmError;
  String? _brandError;
  String? _locationError;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _selectedComponentType = widget.initialComponentType ?? ComponentType.engineOil;
    _selectedDate = DateTime.now();

    _kmController = TextEditingController();
    _brandController = TextEditingController();
    _locationController = TextEditingController();
    _priceController = TextEditingController();
    _noteController = TextEditingController();

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
    _brandController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _noteController.dispose();
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

  bool _validateInputs() {
    String? kmErr;
    String? brandErr;
    String? locErr;
    String? priceErr;

    final kmVal = _kmController.text.replaceAll('.', '').trim();
    if (kmVal.isEmpty) {
      kmErr = 'Kilometer servis wajib diisi';
    } else {
      final parsedKm = int.tryParse(kmVal);
      if (parsedKm == null || parsedKm < 0) {
        kmErr = 'Masukkan angka kilometer yang valid';
      }
    }

    if (_brandController.text.trim().isEmpty) {
      brandErr = 'Merek suku cadang atau oli wajib diisi';
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
        priceErr = 'Masukkan angka biaya yang valid';
      }
    }

    setState(() {
      _kmError = kmErr;
      _brandError = brandErr;
      _locationError = locErr;
      _priceError = priceErr;
    });

    return kmErr == null && brandErr == null && locErr == null && priceErr == null;
  }

  Future<void> _saveService(Vehicle vehicle) async {
    if (!_validateInputs()) {
      return;
    }

    final km = int.parse(_kmController.text.replaceAll('.', '').trim());
    final price = ServiceCalculator.parseRupiahInput(_priceController.text)!;

    final success = await ref.read(serviceControllerProvider.notifier).addServiceRecord(
      vehicleId: vehicle.id,
      componentType: _selectedComponentType,
      date: _selectedDate,
      km: km,
      brand: _brandController.text.trim(),
      price: price,
      location: _locationController.text.trim(),
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan servis tersimpan! Kartu komponen kini 100% aman.'),
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
            ),
            Text(
              activeVehicle.displayName,
              style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
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
              // Banner Motor Aktif (Quick Telemetry Banner di desain)
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

              // Pilihan Komponen Berbentuk Chip (Hanya 3 matic sesuai SPEC F5 & SCREENS.md)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KOMPONEN YANG DISERVIS',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _buildComponentChip(
                        type: ComponentType.engineOil,
                        label: 'Ganti Oli Mesin',
                        icon: Symbols.oil_barrel,
                      ),
                      _buildComponentChip(
                        type: ComponentType.gearOil,
                        label: 'Oli Gardan',
                        icon: Symbols.water_drop,
                      ),
                      _buildComponentChip(
                        type: ComponentType.vBelt,
                        label: 'V-Belt',
                        icon: Symbols.settings,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Input: Odometer Saat Servis (KM) + Tombol "Gunakan KM Terkini"
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ODOMETER SAAT SERVIS (KM)',
                        style: AppTypography.labelCaps(
                          color: AppColors.onSurfaceVariant,
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Symbols.auto_fix_high,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Gunakan KM Terkini (${ServiceCalculator.formatKm(activeVehicle.currentKm)})',
                                style: AppTypography.labelCaps(
                                  color: AppColors.primary,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
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

              // Input: Merek Suku Cadang / Oli (SPEC F5)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEREK SUKU CADANG / OLI',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _brandController,
                    hintText: 'Contoh: SPX2 / Yamalube / Shell / Bando',
                    prefixIcon: const Icon(Symbols.verified, size: 20),
                    errorText: _brandError,
                    onChanged: (_) {
                      if (_brandError != null) setState(() => _brandError = null);
                    },
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

              // Input: Total Biaya Servis
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BIAYA SERVIS & SUKU CADANG',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _priceController,
                    hintText: '145.000',
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

  Widget _buildComponentChip({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedComponentType == type;

    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedComponentType = type);
        }
      },
      avatar: Icon(
        isSelected ? Symbols.check_circle : icon,
        size: 18,
        color: isSelected ? AppColors.onPrimary : AppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.roundedFull,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderSlate,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}
