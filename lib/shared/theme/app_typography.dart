import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Skala tipografi aplikasi MotoCare menggunakan Google Fonts
/// Plus Jakarta Sans (Headings & Metric) dan Inter (Body & Label)
abstract final class AppTypography {
  // Plus Jakarta Sans Styles

  /// 48px, w800, letterSpacing -1.44 (-0.03em)
  static TextStyle displayLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 52 / 48,
        letterSpacing: -1.44,
        color: color,
      );

  /// 36px, w700, letterSpacing -0.72 (-0.02em)
  static TextStyle displayMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 42 / 36,
        letterSpacing: -0.72,
        color: color,
      );

  /// 28px, w700, letterSpacing -0.56 (-0.02em)
  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
        letterSpacing: -0.56,
        color: color,
      );

  /// 22px, w600, letterSpacing -0.22 (-0.01em)
  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        letterSpacing: -0.22,
        color: color,
      );

  /// 18px, w600, letterSpacing 0
  static TextStyle headlineSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        letterSpacing: 0,
        color: color,
      );

  /// 32px, w800, letterSpacing -0.64 (-0.02em), tabular figures
  static TextStyle metricVal({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 36 / 32,
        letterSpacing: -0.64,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  // Inter Styles

  /// 16px, w500, letterSpacing 0
  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        letterSpacing: 0,
        color: color,
      );

  /// 14px, w400, letterSpacing 0
  static TextStyle bodyMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: 0,
        color: color,
      );

  /// 12px, w400, letterSpacing 0.12 (0.01em)
  static TextStyle bodySm({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0.12,
        color: color,
      );

  /// 11px, w700, letterSpacing 0.66 (0.06em)
  static TextStyle labelCaps({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 0.66,
        color: color,
      );

  /// 13px, w600, letterSpacing 0.13 (0.01em)
  static TextStyle labelMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 16 / 13,
        letterSpacing: 0.13,
        color: color,
      );
}
