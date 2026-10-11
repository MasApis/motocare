import 'package:flutter/material.dart';
import '../../core/component_health.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppStatusType {
  safe,
  warning,
  critical,
}

/// Badge status berbentuk pill (rounded-full) dengan titik indikator warna
/// Digunakan untuk menandai status kesehatan komponen: Aman, Peringatan, atau Batas Habis
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.showDot = true,
  });

  /// Factory dari ComponentStatus (core)
  factory AppStatusBadge.fromComponentStatus(
    ComponentStatus status, {
    Key? key,
    String? customLabel,
    bool showDot = true,
  }) {
    switch (status) {
      case ComponentStatus.safe:
        return AppStatusBadge.safe(
          key: key,
          label: customLabel,
          showDot: showDot,
        );
      case ComponentStatus.warning:
        return AppStatusBadge.warning(
          key: key,
          label: customLabel,
          showDot: showDot,
        );
      case ComponentStatus.critical:
        return AppStatusBadge.critical(
          key: key,
          label: customLabel,
          showDot: showDot,
        );
    }
  }


  /// Factory untuk status Aman (> 30% sesuai SPEC)
  factory AppStatusBadge.safe({Key? key, String? label, bool showDot = true}) =>
      AppStatusBadge(
        key: key,
        status: AppStatusType.safe,
        customLabel: label ?? 'Aman',
        showDot: showDot,
      );

  /// Factory untuk status Peringatan (10% - 30% sesuai SPEC)
  factory AppStatusBadge.warning({Key? key, String? label, bool showDot = true}) =>
      AppStatusBadge(
        key: key,
        status: AppStatusType.warning,
        customLabel: label ?? 'Peringatan',
        showDot: showDot,
      );

  /// Factory untuk status Batas Habis (< 10% sesuai SPEC)
  factory AppStatusBadge.critical({Key? key, String? label, bool showDot = true}) =>
      AppStatusBadge(
        key: key,
        status: AppStatusType.critical,
        customLabel: label ?? 'Batas habis',
        showDot: showDot,
      );

  final AppStatusType status;
  final String? customLabel;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color indicatorColor;
    String labelText;

    switch (status) {
      case AppStatusType.safe:
        backgroundColor = AppColors.statusSafeBg;
        textColor = AppColors.statusSafeText;
        indicatorColor = AppColors.statusSafeIndicator;
        labelText = customLabel ?? 'Aman';
        break;
      case AppStatusType.warning:
        backgroundColor = AppColors.statusWarningBg;
        textColor = AppColors.statusWarningText;
        indicatorColor = AppColors.statusWarningIndicator;
        labelText = customLabel ?? 'Peringatan';
        break;
      case AppStatusType.critical:
        backgroundColor = AppColors.statusCriticalBg;
        textColor = AppColors.statusCriticalText;
        indicatorColor = AppColors.statusCriticalIndicator;
        labelText = customLabel ?? 'Batas habis';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2, // 10px
        vertical: AppSpacing.xs, // 4px
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppShapes.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 1), // 5px
          ],
          Text(
            labelText,
            style: AppTypography.labelCaps(color: textColor),
          ),
        ],
      ),
    );
  }
}
