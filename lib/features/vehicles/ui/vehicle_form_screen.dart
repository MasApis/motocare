import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../core/vehicle_components.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/vehicle_repository.dart';
import '../providers/vehicle_providers.dart';

/// Layar Tambah / Ubah Motor
/// Mengacu pada docs/design/setup_pertama_kali_motor_motosense/
/// dengan field yang difilter sesuai docs/design/SCREENS.md
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({
    super.key,
    this.vehicleId,
  });

  /// Jika null, layar berada dalam mode Tambah Motor.
  /// Jika terisi, layar berada dalam mode Ubah Data Motor.
  final String? vehicleId;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  String _selectedBrand = VehiclePresets.brands.first;
  bool _isManualModel = false;
  String _selectedPresetModel = '';

  final _modelController = TextEditingController();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _kmController = TextEditingController();

  // Controller interval per komponen
  final _engineOilIntervalController = TextEditingController(
    text: DefaultIntervals.engineOil.toString(),
  );
  final _gearOilIntervalController = TextEditingController(
    text: DefaultIntervals.gearOil.toString(),
  );
  final _vBeltIntervalController = TextEditingController(
    text: DefaultIntervals.vBelt.toString(),
  );

  // Error texts
  String? _modelError;
  String? _kmError;
  String? _engineOilError;
  String? _gearOilError;
  String? _vBeltError;

  bool _isLoading = false;
  bool _isInitialDataLoaded = false;

  bool get isEditMode => widget.vehicleId != null;

  @override
  void initState() {
    super.initState();
    _updatePresetModelOptions();
  }

  void _updatePresetModelOptions() {
    final availablePresets = VehiclePresets.models
        .where((m) => m.brand == _selectedBrand)
        .toList();

    if (availablePresets.isNotEmpty) {
      if (!_isManualModel) {
        _selectedPresetModel = availablePresets.first.model;
        _modelController.text = _selectedPresetModel;
      }
    } else {
      _isManualModel = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isEditMode && !_isInitialDataLoaded) {
      _loadExistingVehicle();
    }
  }

  Future<void> _loadExistingVehicle() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(vehicleRepositoryProvider);
      final vehicle = await repo.getVehicle(widget.vehicleId!);
      if (vehicle != null && mounted) {
        _selectedBrand = vehicle.brand;
        _modelController.text = vehicle.model;
        _nameController.text = vehicle.name;
        _plateController.text = vehicle.plate ?? '';
        _kmController.text = vehicle.currentKm.toString();

        final isKnownPreset = VehiclePresets.models.any(
          (m) => m.brand == vehicle.brand && m.model == vehicle.model,
        );

        if (isKnownPreset) {
          _isManualModel = false;
          _selectedPresetModel = vehicle.model;
        } else {
          _isManualModel = true;
        }

        // Ambil komponen untuk mengisi interval
        final components = await repo.watchComponents(vehicle.id).first;
        for (final c in components) {
          if (c.type == ComponentType.engineOil) {
            _engineOilIntervalController.text = c.intervalKm.toString();
          } else if (c.type == ComponentType.gearOil) {
            _gearOilIntervalController.text = c.intervalKm.toString();
          } else if (c.type == ComponentType.vBelt) {
            _vBeltIntervalController.text = c.intervalKm.toString();
          }
        }
      }
    } catch (_) {
      // Abaikan jika gagal memuat
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialDataLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _nameController.dispose();
    _plateController.dispose();
    _kmController.dispose();
    _engineOilIntervalController.dispose();
    _gearOilIntervalController.dispose();
    _vBeltIntervalController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _modelError = null;
      _kmError = null;
      _engineOilError = null;
      _gearOilError = null;
      _vBeltError = null;

      final model = _modelController.text.trim();
      if (model.isEmpty) {
        _modelError = 'Model motor wajib diisi.';
        isValid = false;
      }

      final kmText = _kmController.text.replaceAll('.', '').trim();
      if (kmText.isEmpty) {
        _kmError = 'Angka KM speedometer wajib diisi.';
        isValid = false;
      } else {
        final kmVal = int.tryParse(kmText);
        if (kmVal == null || kmVal < 0) {
          _kmError = 'Masukkan angka kilometer yang valid (≥ 0).';
          isValid = false;
        }
      }

      final eOil = int.tryParse(_engineOilIntervalController.text.trim());
      if (eOil == null || eOil <= 0) {
        _engineOilError = 'Interval oli mesin harus > 0 km.';
        isValid = false;
      }

      final gOil = int.tryParse(_gearOilIntervalController.text.trim());
      if (gOil == null || gOil <= 0) {
        _gearOilError = 'Interval oli gardan harus > 0 km.';
        isValid = false;
      }

      final vBelt = int.tryParse(_vBeltIntervalController.text.trim());
      if (vBelt == null || vBelt <= 0) {
        _vBeltError = 'Interval V-belt harus > 0 km.';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    final brand = _selectedBrand;
    final model = _modelController.text.trim();
    final name = _nameController.text.trim();
    final plate = _plateController.text.trim();
    final currentKm = int.tryParse(_kmController.text.replaceAll('.', '')) ?? 0;

    final engineOilInterval = int.tryParse(
          _engineOilIntervalController.text.replaceAll('.', ''),
        ) ??
        DefaultIntervals.engineOil;
    final gearOilInterval = int.tryParse(
          _gearOilIntervalController.text.replaceAll('.', ''),
        ) ??
        DefaultIntervals.gearOil;
    final vBeltInterval = int.tryParse(
          _vBeltIntervalController.text.replaceAll('.', ''),
        ) ??
        DefaultIntervals.vBelt;

    final customIntervals = {
      ComponentType.engineOil: engineOilInterval,
      ComponentType.gearOil: gearOilInterval,
      ComponentType.vBelt: vBeltInterval,
    };

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(vehicleControllerProvider);

      if (isEditMode) {
        await controller.updateVehicle(
          vehicleId: widget.vehicleId!,
          brand: brand,
          model: model,
          name: name.isNotEmpty ? name : '$brand $model',
          plate: plate.isNotEmpty ? plate : null,
          currentKm: currentKm,
          customIntervals: customIntervals,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data motor berhasil diperbarui.')),
          );
          context.pop();
        }
      } else {
        final newId = await controller.addVehicle(
          brand: brand,
          model: model,
          name: name.isNotEmpty ? name : '$brand $model',
          plate: plate.isNotEmpty ? plate : null,
          currentKm: currentKm,
          customIntervals: customIntervals,
        );
        ref.read(selectedVehicleIdProvider.notifier).select(newId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Motor berhasil didaftarkan!')),
          );
          context.pop();
        }
      }
    } on VehicleException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availablePresets = VehiclePresets.models
        .where((m) => m.brand == _selectedBrand)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isEditMode ? 'Ubah Data Motor' : 'Daftarkan Motor',
          style: AppTypography.headlineSm(),
        ),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Kembali',
        ),
      ),
      body: _isLoading && !isEditMode
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                children: [
                  // Heading singkat
                  Text(
                    isEditMode
                        ? 'Perbarui Spesifikasi Motor'
                        : 'Setup Motor Matik Kamu',
                    style: AppTypography.headlineLg(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Masukkan data motor agar jadwal servis dapat dipantau secara akurat.',
                    style: AppTypography.bodyMd(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // SEKSI 1: Spesifikasi Pabrikan
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Symbols.sports_motorsports,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'SPESIFIKASI PABRIKAN',
                              style: AppTypography.labelCaps(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer
                                    .withValues(alpha: 0.2),
                                borderRadius: AppShapes.roundedFull,
                              ),
                              child: Text(
                                'Wajib',
                                style: AppTypography.labelCaps(
                                  color: AppColors.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          height: 24,
                          color: AppColors.surfaceContainer,
                        ),

                        // Pilihan Merek
                        Text(
                          'Merk Pabrikan',
                          style: AppTypography.labelMd(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedBrand),
                          initialValue: _selectedBrand,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceContainerLow,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppShapes.roundedDefault,
                              borderSide: const BorderSide(
                                color: AppColors.outlineVariant,
                              ),
                            ),
                          ),
                          items: VehiclePresets.brands.map((brand) {
                            return DropdownMenuItem<String>(
                              value: brand,
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryFixed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      brand[0],
                                      style: AppTypography.labelCaps(
                                        color: AppColors.onPrimaryFixed,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    brand,
                                    style: AppTypography.bodyMd(
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newBrand) {
                            if (newBrand != null) {
                              setState(() {
                                _selectedBrand = newBrand;
                                _updatePresetModelOptions();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Pilihan Model: Preset vs Ketik Manual
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Model Motor Matik',
                              style: AppTypography.labelMd(),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isManualModel = !_isManualModel;
                                  if (!_isManualModel) {
                                    _updatePresetModelOptions();
                                  }
                                });
                              },
                              child: Text(
                                _isManualModel
                                    ? 'Pilih dari Preset'
                                    : 'Ketik Manual',
                                style: AppTypography.labelCaps(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!_isManualModel && availablePresets.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            key: ValueKey('${_selectedBrand}_$_selectedPresetModel'),
                            initialValue: availablePresets.any(
                                    (m) => m.model == _selectedPresetModel)
                                ? _selectedPresetModel
                                : availablePresets.first.model,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surfaceContainerLow,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppShapes.roundedDefault,
                                borderSide: const BorderSide(
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                            ),
                            items: availablePresets.map((preset) {
                              return DropdownMenuItem<String>(
                                value: preset.model,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Symbols.moped,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      preset.model,
                                      style: AppTypography.bodyMd(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedPresetModel = val;
                                  _modelController.text = val;
                                  _modelError = null;
                                });
                              }
                            },
                          ),
                        ] else ...[
                          AppTextField(
                            controller: _modelController,
                            hintText: 'Contoh: Vario 160 eSP+, Beat Street',
                            errorText: _modelError,
                            prefixIcon: const Icon(
                              Symbols.moped,
                              color: AppColors.primary,
                            ),
                            onChanged: (_) {
                              if (_modelError != null) {
                                setState(() => _modelError = null);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // SEKSI 2: Identitas Kendaraan
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Symbols.badge,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'IDENTITAS KENDARAAN',
                              style: AppTypography.labelCaps(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: AppShapes.roundedFull,
                              ),
                              child: Text(
                                'Opsional',
                                style: AppTypography.labelCaps(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          height: 24,
                          color: AppColors.surfaceContainer,
                        ),

                        // Plat Nomor
                        Text(
                          'Nomor Polisi (Plat)',
                          style: AppTypography.labelMd(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _plateController,
                          hintText: 'Contoh: B 1234 KLS',
                          prefixIcon: const Icon(
                            Symbols.pin,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Nama Panggilan Motor
                        Text(
                          'Nama Panggilan Motor',
                          style: AppTypography.labelMd(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _nameController,
                          hintText: 'Contoh: Si Merah, Motor Harian',
                          prefixIcon: const Icon(
                            Symbols.tag,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Opsional. Jika kosong, nama model akan digunakan sebagai nama utama.',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // SEKSI 3: Speedometer KM Saat Ini
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Symbols.speed,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'ODOMETER SAAT INI',
                              style: AppTypography.labelCaps(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer
                                    .withValues(alpha: 0.2),
                                borderRadius: AppShapes.roundedFull,
                              ),
                              child: Text(
                                'Wajib',
                                style: AppTypography.labelCaps(
                                  color: AppColors.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          height: 24,
                          color: AppColors.surfaceContainer,
                        ),
                        Text(
                          'Kilometer Speedometer Saat Ini',
                          style: AppTypography.labelMd(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _kmController,
                          hintText: 'Misal: 14280',
                          errorText: _kmError,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: const Icon(
                            Symbols.speed,
                            color: AppColors.primary,
                          ),
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Text(
                              'KM',
                              style: AppTypography.labelMd(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            if (_kmError != null) {
                              setState(() => _kmError = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // SEKSI 4: Pengaturan Interval Komponen (SPEC F2: Interval tiap komponen bisa diubah per motor)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Symbols.tune,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'INTERVAL SERVIS KOMPONEN',
                              style: AppTypography.labelCaps(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Interval default disesuaikan dengan rekomendasi matik. Anda dapat mengubahnya sesuai buku manual motor.',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const Divider(
                          height: 24,
                          color: AppColors.surfaceContainer,
                        ),

                        // Interval Oli Mesin
                        Text(
                          'Interval Oli Mesin (KM)',
                          style: AppTypography.labelMd(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _engineOilIntervalController,
                          errorText: _engineOilError,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: const Icon(
                            Symbols.oil_barrel,
                            color: AppColors.primary,
                          ),
                          onChanged: (_) {
                            if (_engineOilError != null) {
                              setState(() => _engineOilError = null);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Interval Oli Gardan
                        Text(
                          'Interval Oli Gardan / Transmisi (KM)',
                          style: AppTypography.labelMd(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _gearOilIntervalController,
                          errorText: _gearOilError,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: const Icon(
                            Symbols.settings_slow_motion,
                            color: AppColors.primary,
                          ),
                          onChanged: (_) {
                            if (_gearOilError != null) {
                              setState(() => _gearOilError = null);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Interval V-Belt
                        Text(
                          'Interval V-Belt (KM)',
                          style: AppTypography.labelMd(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          controller: _vBeltIntervalController,
                          errorText: _vBeltError,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: const Icon(
                            Symbols.all_inclusive,
                            color: AppColors.primary,
                          ),
                          onChanged: (_) {
                            if (_vBeltError != null) {
                              setState(() => _vBeltError = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Tombol Simpan
                  AppButton(
                    text: isEditMode ? 'Simpan Perubahan' : 'Simpan & Pantau Motor',
                    isLoading: _isLoading,
                    icon: const Icon(
                      Symbols.arrow_forward,
                      size: 20,
                      color: AppColors.onPrimary,
                    ),
                    onPressed: _submitForm,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
    );
  }
}
