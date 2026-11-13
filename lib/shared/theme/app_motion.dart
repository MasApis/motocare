import 'package:flutter/widgets.dart';

/// Aturan gerak (animasi) aplikasi MotoCare, didefinisikan sekali di sini.
/// Animasi dibuat halus dan singkat agar tetap mudah dibaca sekilas (docs/DESIGN.md).
abstract final class AppMotion {
  /// Durasi transisi cepat (efek tekan, ganti tab)
  static const Duration fast = Duration(milliseconds: 150);

  /// Durasi kartu muncul
  static const Duration entrance = Duration(milliseconds: 450);

  /// Jeda antar kartu yang muncul bergantian
  static const Duration stagger = Duration(milliseconds: 70);

  /// Durasi progress bar terisi dan angka menghitung naik
  static const Duration fill = Duration(milliseconds: 900);

  /// Kurva standar: cepat di awal, melambat di akhir
  static const Curve curve = Curves.easeOutCubic;

  /// Skala saat kartu/tombol ditekan (desain: active:scale-[0.98])
  static const double pressedScale = 0.98;

  /// Jarak geser ke atas saat kartu muncul (dp)
  static const double entranceOffset = 16;

  /// True jika pengguna mematikan animasi di pengaturan aksesibilitas HP
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
