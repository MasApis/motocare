import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../../core/component_health.dart';
import '../../../../core/vehicle_components.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_shapes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/app_status_badge.dart';

/// Kartu status kesehatan komponen motor
/// Menampilkan ikon, nama komponen, interval, badge status (Aman/Peringatan/Batas habis),
/// progress bar pemakaian, persentase terpakai, dan sisa jarak tempuh (km).
/// Mengikuti desain docs/design/beranda_status_motor_2 dan aturan docs/SPEC.md (F3).
class ComponentHealthCard extends StatelessWidget {
  const ComponentHealthCard({
    super.key,
    required this.componentType,
    required this.intervalKm,
    required this.lastServiceKm,
    required this.currentKm,
    this.onTap,
  });

  /// Tipe komponen: engine_oil, gear_oil, atau v_belt
  final String componentType;

  /// Interval rekomendasi penggantian komponen (km)
  final int intervalKm;

  /// Kilometer saat servis terakhir (km)
  final int lastServiceKm;

  /// Kilometer odometer motor saat ini (km)
  final int currentKm;

  /// Callback opsional saat kartu ditekan (untuk F5)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final health = calculateComponentHealth(
      intervalKm: intervalKm,
      currentKm: currentKm,
      lastServiceKm: lastServiceKm,
    );

    final iconData = _getComponentIcon(componentType);
    final componentName = ComponentType.getLabel(componentType);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: AppColors.borderSlate,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppShapes.roundedDefault,
        child: InkWell(
          borderRadius: AppShapes.roundedDefault,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Baris Atas: Ikon + Judul + Badge Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lingkaran Ikon Komponen
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: health.backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: health.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Nama Komponen & Interval
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            componentName,
                            style: AppTypography.labelMd().copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Interval tiap ${_formatKm(intervalKm)} km',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Badge Status (Aman / Peringatan / Batas habis)
                    AppStatusBadge.fromComponentStatus(health.status),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Progress Bar Pemakaian
                AppProgressBar(
                  percentageUsed: health.usedPercentage / 100.0,
                  customBarColor: health.color,
                  height: 8.0,
                ),

                const SizedBox(height: AppSpacing.xs),

                // Teks Metrik di Bawah Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Persentase Terpakai
                    Text(
                      '${health.usedPercentage.round()}% terpakai',
                      style: AppTypography.labelCaps(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),

                    // Sisa Jarak KM (atau Lewat X km jika melebihi interval)
                    Text(
                      _formatRemainingKmText(health.remainingKm),
                      style: AppTypography.labelCaps(
                        color: health.status == ComponentStatus.safe
                            ? AppColors.onSurfaceVariant
                            : health.color,
                      ).copyWith(
                        fontWeight: health.status == ComponentStatus.safe
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Memilih ikon representatif untuk setiap jenis komponen matic
  IconData _getComponentIcon(String type) {
    switch (type) {
      case ComponentType.engineOil:
        return Symbols.oil_barrel;
      case ComponentType.gearOil:
        return Symbols.settings_slow_motion;
      case ComponentType.vBelt:
        return Symbols.sync_saved_locally;
      default:
        return Symbols.build_circle;
    }
  }

  /// Format teks sisa KM yang ramah pengguna
  String _formatRemainingKmText(int remainingKm) {
    if (remainingKm >= 0) {
      return 'Sisa ${_formatKm(remainingKm)} km';
    } else {
      return 'Lewat ${_formatKm(-remainingKm)} km';
    }
  }

  /// Format angka integer dengan pemisah titik ribuan (misal 2.000)
  String _formatKm(int km) {
    final str = km.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
