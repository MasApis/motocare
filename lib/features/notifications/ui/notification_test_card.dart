import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../providers/notification_providers.dart';

/// Card Mode Uji Sementara (Bertanda jelas) untuk pengujian F6
/// Memungkinkan penguji memverifikasi notifikasi dalam 5 detik di HP fisik
/// tanpa perlu menunggu berhari-hari.
class NotificationTestCard extends ConsumerStatefulWidget {
  const NotificationTestCard({
    super.key,
    required this.vehicle,
  });

  final Vehicle vehicle;

  @override
  ConsumerState<NotificationTestCard> createState() =>
      _NotificationTestCardState();
}

class _NotificationTestCardState extends ConsumerState<NotificationTestCard> {
  bool _isScheduled = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceContainerLow,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: AppShapes.roundedSm,
                ),
                child: const Icon(
                  Symbols.science,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🧪 Mode Uji Notifikasi',
                          style: AppTypography.labelMd().copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusWarningBg,
                            borderRadius: AppShapes.roundedFull,
                          ),
                          child: Text(
                            'UJI COBA F6',
                            style: AppTypography.labelCaps(
                              color: AppColors.statusWarningText,
                            ).copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Uji alarm tanpa menunggu berhari-hari. Notifikasi akan berbunyi dalam 5 detik.',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: AppShapes.shapePill,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              onPressed: _isScheduled
                  ? null
                  : () async {
                      setState(() => _isScheduled = true);
                      try {
                        await ref
                            .read(notificationSchedulerProvider)
                            .triggerTestNotification(widget.vehicle.displayName);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 4),
                              content: Text(
                                '🧪 Notifikasi uji dijadwalkan dalam 5 detik! Anda dapat keluar/kunci HP untuk menguji.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          Future.delayed(const Duration(seconds: 6), () {
                            if (mounted) {
                              setState(() => _isScheduled = false);
                            }
                          });
                        }
                      }
                    },
              icon: _isScheduled
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Symbols.schedule_send, size: 18),
              label: Text(
                _isScheduled
                  ? 'Menunggu 5 detik...'
                  : 'Kirim Notifikasi Uji (5 Detik)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
