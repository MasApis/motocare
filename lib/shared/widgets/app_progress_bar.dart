import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_status_badge.dart';

/// Progress bar melengkung untuk visualisasi pemakaian komponen motor
/// Sesuai docs/DESIGN.md & docs/design/SCREENS.md
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.percentageUsed,
    this.status = AppStatusType.safe,
    this.customBarColor,
    this.height = 8.0,
    this.leftLabel,
    this.rightLabel,
  });

  /// Persentase terpakai dalam rentang 0.0 sampai 1.0 (misal 0.85 = 85%)
  final double percentageUsed;

  /// Status semantik untuk penentuan warna otomatis jika [customBarColor] tidak diatur
  final AppStatusType status;

  /// Warna custom opsional untuk fill progress bar
  final Color? customBarColor;

  /// Tinggi progress bar (standar 8.0)
  final double height;

  /// Teks keterangan di bawah sisi kiri (contoh: "85% terpakai")
  final String? leftLabel;

  /// Teks keterangan di bawah sisi kanan (contoh: "Sisa 420 km")
  final String? rightLabel;

  @override
  Widget build(BuildContext context) {
    final clampedRatio = percentageUsed.clamp(0.0, 1.0);

    Color barColor;
    if (customBarColor != null) {
      barColor = customBarColor!;
    } else {
      switch (status) {
        case AppStatusType.safe:
          barColor = AppColors.statusSafeIndicator;
          break;
        case AppStatusType.warning:
          barColor = AppColors.statusWarningIndicator;
          break;
        case AppStatusType.critical:
          barColor = AppColors.statusCriticalIndicator;
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Track & Fill bar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: AppShapes.roundedFull,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * clampedRatio;
              return Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: fillWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: AppShapes.roundedFull,
                  ),
                ),
              );
            },
          ),
        ),

        // Label teks di bawah jika disediakan
        if (leftLabel != null || rightLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leftLabel != null)
                Text(
                  leftLabel!,
                  style: AppTypography.labelCaps(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (rightLabel != null)
                Text(
                  rightLabel!,
                  style: AppTypography.labelCaps(
                    color: status == AppStatusType.critical
                        ? AppColors.statusCriticalIndicator
                        : (status == AppStatusType.warning
                            ? AppColors.statusWarningIndicator
                            : AppColors.onSurfaceVariant),
                  ).copyWith(
                    fontWeight: status != AppStatusType.safe
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ],
    );
  }
}
