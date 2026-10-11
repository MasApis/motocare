import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  tonal,
}

/// Tombol utama dan sekunder bersudut pill (rounded-full)
/// Memiliki tinggi standar 52px (primary) atau 48px sesuai docs/DESIGN.md
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.surfaceContainerHigh;
        foregroundColor = isEnabled ? AppColors.onPrimary : AppColors.outline;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.onSurface : AppColors.outline;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.borderSlate : AppColors.outlineVariant,
          width: 1.5,
        );
        break;
      case AppButtonVariant.tonal:
        backgroundColor = isEnabled ? AppColors.surfaceContainer : AppColors.surfaceContainerLow;
        foregroundColor = isEnabled ? AppColors.onSurfaceVariant : AppColors.outline;
        break;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            icon!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              text,
              style: AppTypography.labelMd(color: foregroundColor).copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: variant == AppButtonVariant.primary && isEnabled ? 2 : 0,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      shape: AppShapes.shapePill.copyWith(side: borderSide),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      minimumSize: Size(isFullWidth ? double.infinity : 64.0, height),
    );

    return ElevatedButton(
      style: buttonStyle,
      onPressed: isEnabled ? onPressed : null,
      child: content,
    );
  }
}
