import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/notification_providers.dart';

/// Banner edukatif yang meminta izin notifikasi dengan sopan
/// dan menjelaskan dampaknya jika ditolak sesuai docs/SPEC.md (F6).
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(notificationPermissionProvider);

    return permissionAsync.when(
      data: (isGranted) {
        if (isGranted) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.statusWarningBg,
            borderRadius: AppShapes.roundedDefault,
            border: Border.all(
              color: AppColors.statusWarningIndicator.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Symbols.notifications_off,
                    color: AppColors.statusWarningText,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengingat Servis Belum Aktif',
                          style: AppTypography.labelMd(
                            color: AppColors.statusWarningText,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Izin notifikasi belum diaktifkan. Anda tidak akan menerima pengingat otomatis saat oli atau V-belt mendekati batas habis.',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    shape: AppShapes.shapePill,
                  ),
                  onPressed: () async {
                    final granted = await ref
                        .read(notificationPermissionProvider.notifier)
                        .requestPermission();
                    if (context.mounted) {
                      if (granted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Izin notifikasi aktif! Pengingat servis otomatis telah diaktifkan.',
                            ),
                          ),
                        );
                        // Langsung sinkronkan jadwal setelah izin diberikan
                        await ref
                            .read(notificationSchedulerProvider)
                            .syncSelectedVehicleNotifications();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Izin belum diberikan. Anda dapat mengaktifkannya kapan saja di Pengaturan HP.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Symbols.notifications_active, size: 16),
                  label: const Text('Aktifkan Notifikasi'),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
