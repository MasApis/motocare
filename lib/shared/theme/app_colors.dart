import 'package:flutter/material.dart';

/// Definisi palet warna aplikasi MotoCare sesuai docs/DESIGN.md
abstract final class AppColors {
  // Surface & Canvas
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceDim = Color(0xFFD2D9F4);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);

  // Content on Surface
  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF3F4850);
  static const Color inverseSurface = Color(0xFF283044);
  static const Color inverseOnSurface = Color(0xFFEEF0FF);

  // Outlines & Borders
  static const Color outline = Color(0xFF707881);
  static const Color outlineVariant = Color(0xFFBFC7D2);
  static const Color borderSlate = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Primary
  static const Color primary = Color(0xFF006194);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF007BB9);
  static const Color onPrimaryContainer = Color(0xFFFDFCFF);
  static const Color primaryFixed = Color(0xFFCCE5FF);
  static const Color primaryFixedDim = Color(0xFF93CCFF);
  static const Color onPrimaryFixed = Color(0xFF001D31);
  static const Color onPrimaryFixedVariant = Color(0xFF004B73);
  static const Color inversePrimary = Color(0xFF93CCFF);
  static const Color surfaceTint = Color(0xFF006398);

  // Secondary
  static const Color secondary = Color(0xFF006591);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF39B8FD);
  static const Color onSecondaryContainer = Color(0xFF004666);
  static const Color secondaryFixed = Color(0xFFC9E6FF);
  static const Color secondaryFixedDim = Color(0xFF89CEFF);
  static const Color onSecondaryFixed = Color(0xFF001E2F);
  static const Color onSecondaryFixedVariant = Color(0xFF004C6E);

  // Tertiary
  static const Color tertiary = Color(0xFF006947);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF00855B);
  static const Color onTertiaryContainer = Color(0xFFF5FFF6);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color tertiaryFixedDim = Color(0xFF4EDEA3);
  static const Color onTertiaryFixed = Color(0xFF002113);
  static const Color onTertiaryFixedVariant = Color(0xFF005236);

  // Error & Critical
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Status Semantics (Optimal, Advisory, Critical)
  // Aman (Optimal / Healthy)
  static const Color statusSafeBg = Color(0xFFECFDF5);
  static const Color statusSafeText = Color(0xFF065F46);
  static const Color statusSafeIndicator = Color(0xFF10B981);

  // Peringatan (Advisory / Warning)
  static const Color statusWarningBg = Color(0xFFFFFBEB);
  static const Color statusWarningText = Color(0xFF92400E);
  static const Color statusWarningIndicator = Color(0xFFF59E0B);

  // Batas Habis (Critical / Fault)
  static const Color statusCriticalBg = Color(0xFFFEF2F2);
  static const Color statusCriticalText = Color(0xFF991B1B);
  static const Color statusCriticalIndicator = Color(0xFFEF4444);
}
