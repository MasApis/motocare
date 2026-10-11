import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_typography.dart';

/// Konfigurasi tema global ThemeData untuk MotoCare
abstract final class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      displayLarge: AppTypography.displayLg(),
      displayMedium: AppTypography.displayMd(),
      headlineLarge: AppTypography.headlineLg(),
      headlineMedium: AppTypography.headlineMd(),
      headlineSmall: AppTypography.headlineSm(),
      bodyLarge: AppTypography.bodyLg(),
      bodyMedium: AppTypography.bodyMd(),
      bodySmall: AppTypography.bodySm(),
      labelLarge: AppTypography.labelMd(),
      labelMedium: AppTypography.labelMd(),
      labelSmall: AppTypography.labelCaps(),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSm(),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: AppShapes.shapeCard,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
