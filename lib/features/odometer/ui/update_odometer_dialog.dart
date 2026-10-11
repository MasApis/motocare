import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../core/validators.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../providers/odometer_providers.dart';

/// Modal dialog form update odometer sesuai desain beranda_status_motor_2
/// dan docs/SPEC.md (F4).
class UpdateOdometerDialog extends ConsumerStatefulWidget {
  const UpdateOdometerDialog({
    super.key,
    required this.vehicle,
  });

  final Vehicle vehicle;

  static Future<bool?> show(BuildContext context, Vehicle vehicle) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpdateOdometerDialog(vehicle: vehicle),
    );
  }

  @override
  ConsumerState<UpdateOdometerDialog> createState() =>
      _UpdateOdometerDialogState();
}

class _UpdateOdometerDialogState extends ConsumerState<UpdateOdometerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmController;
  late DateTime _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default nilai awal di form adalah KM saat ini
    _kmController = TextEditingController(text: widget.vehicle.currentKm.toString());
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Pilih Tanggal Pencatatan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawKm = _kmController.text.trim().replaceAll('.', '').replaceAll(',', '');
    final newKm = int.parse(rawKm);

    setState(() => _isLoading = true);

    try {
      await ref.read(odometerControllerProvider).updateOdometer(
            vehicleId: widget.vehicle.id,
            km: newKm,
            date: _selectedDate,
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: AppShapes.roundedDefault,
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.speed,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Update Odometer',
                            style: AppTypography.headlineSm().copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Symbols.close, size: 20),
                        tooltip: 'Tutup',
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Masukkan angka speedometer motor saat ini untuk memperbarui perkiraan jadwal servis.',
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Label Input KM
                  Text(
                    'ANGKA KILOMETER BARU (KM)',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Input KM
                  TextFormField(
                    controller: _kmController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.headlineSm().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      suffixText: 'KM',
                      suffixStyle: AppTypography.labelMd(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontWeight: FontWeight.w700),
                      errorMaxLines: 3,
                      errorStyle: AppTypography.bodySm(
                        color: AppColors.error,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: AppShapes.roundedDefault,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppShapes.roundedDefault,
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderRadius: AppShapes.roundedDefault,
                        borderSide: BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderRadius: AppShapes.roundedDefault,
                        borderSide: BorderSide(color: AppColors.error, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    validator: (value) =>
                        validateOdometerInput(value, widget.vehicle.currentKm),
                  ),
                  const SizedBox(height: 4),

                  // Info KM sebelumnya
                  Text(
                    'Tercatat sebelumnya: ${_formatNumber(widget.vehicle.currentKm)} KM',
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Label Tanggal
                  Text(
                    'TANGGAL PENCATATAN',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Pemilih Tanggal (default hari ini)
                  InkWell(
                    onTap: _isLoading ? null : _pickDate,
                    borderRadius: AppShapes.roundedDefault,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppShapes.roundedDefault,
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Symbols.calendar_today,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _formatDate(_selectedDate),
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Ubah',
                            style: AppTypography.labelMd(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pesan error jika ada
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      style: AppTypography.bodySm(color: AppColors.error),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Tombol Aksi Batal dan Simpan
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: AppColors.outlineVariant),
                            shape: AppShapes.shapePill,
                            foregroundColor: AppColors.onSurfaceVariant,
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: AppShapes.shapePill,
                            elevation: 1,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(AppColors.onPrimary),
                                  ),
                                )
                              : const Text(
                                  'Simpan KM',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
