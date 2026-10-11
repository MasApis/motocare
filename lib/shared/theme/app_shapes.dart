import 'package:flutter/material.dart';

/// Definisi bentuk kelengkungan (border radius) aplikasi MotoCare sesuai docs/DESIGN.md
abstract final class AppShapes {
  /// Radius 8.0 (0.5rem - sm)
  static const double radiusSm = 8.0;

  /// Radius 16.0 (1rem - DEFAULT)
  static const double radiusDefault = 16.0;

  /// Radius 24.0 (1.5rem - md)
  static const double radiusMd = 24.0;

  /// Radius 32.0 (2rem - lg)
  static const double radiusLg = 32.0;

  /// Radius 48.0 (3rem - xl)
  static const double radiusXl = 48.0;

  /// Radius Pill 9999.0 (full)
  static const double radiusFull = 9999.0;

  // BorderRadius objects
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedDefault = BorderRadius.all(Radius.circular(radiusDefault));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // RoundedRectangleBorder for Buttons & Cards
  static const RoundedRectangleBorder shapePill = RoundedRectangleBorder(
    borderRadius: roundedFull,
  );

  static const RoundedRectangleBorder shapeCard = RoundedRectangleBorder(
    borderRadius: roundedDefault,
  );
}
