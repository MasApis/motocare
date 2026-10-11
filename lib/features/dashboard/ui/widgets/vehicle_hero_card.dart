import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../../core/odometer_calculator.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_shapes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../odometer/providers/odometer_providers.dart';
import '../../../odometer/ui/update_odometer_dialog.dart';
import '../../../vehicles/data/models/vehicle_model.dart';

/// Kartu Hero Motor di Carousel Dashboard sesuai acuan visual
/// docs/design/beranda_status_motor_2 dan fitur F2/F4.
class VehicleHeroCard extends ConsumerWidget {
  const VehicleHeroCard({
    super.key,
    required this.vehicle,
    required this.itemNumber,
    required this.totalItems,
  });

  final Vehicle vehicle;
  final int itemNumber;
  final int totalItems;

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

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diffDays = calendarDaysDifference(date, now);
    if (diffDays <= 0) {
      return 'Hari ini';
    } else if (diffDays == 1) {
      return 'Kemarin';
    } else {
      return '$diffDays hari lalu';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(odometerLogsStreamProvider(vehicle.id));
    final logs = logsAsync.asData?.value ?? [];

    // Hitung rata-rata KM harian dari entri odometer
    final entries = logs.map((l) => l.toOdometerEntry()).toList();
    final dailyAvg = calculateDailyAverageKm(entries);

    // Ambil tanggal catatan terakhir
    final latestLogDate = logs.isNotEmpty ? logs.first.date : vehicle.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris Atas: Label & Tombol Edit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'MOTOR $itemNumber DARI $totalItems',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Symbols.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: 'Ubah Data Motor',
                onPressed: () => context.push('/vehicles/edit/${vehicle.id}'),
              ),
            ],
          ),

          // Nama Motor & Plat
          Text(
            vehicle.displayName,
            style: AppTypography.headlineMd().copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            vehicle.plate != null && vehicle.plate!.isNotEmpty
                ? '${vehicle.brand} ${vehicle.model} • ${vehicle.plate}'
                : '${vehicle.brand} ${vehicle.model}',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Box Odometer Showcase
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppShapes.roundedDefault,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ODOMETER TERCATAT',
                      style: AppTypography.labelCaps(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: AppShapes.roundedFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Symbols.schedule,
                            size: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeAgo(latestLogDate),
                            style: AppTypography.labelCaps(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatKm(vehicle.currentKm),
                      style: AppTypography.headlineLg().copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'KM',
                      style: AppTypography.labelMd(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Rata-rata KM Harian sesuai SPEC
                Row(
                  children: [
                    const Icon(
                      Symbols.trending_up,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rata-rata ',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatDailyAverageKm(dailyAvg),
                      style: AppTypography.bodySm(
                        color: AppColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Prominent Update CTA Button sesuai desain
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final updated = await UpdateOdometerDialog.show(context, vehicle);
                if (updated == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Angka odometer "${vehicle.displayName}" berhasil diperbarui.'),
                    ),
                  );
                }
              },
              icon: const Icon(Symbols.add_circle, size: 20),
              label: const Text(
                'Update KM Hari Ini',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: AppShapes.shapePill,
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
