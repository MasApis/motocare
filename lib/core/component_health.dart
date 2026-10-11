import 'package:flutter/material.dart';

import '../shared/theme/app_colors.dart';

/// Ambang batas persentase status kesehatan komponen motor
/// sesuai dengan docs/SPEC.md bagian 2.1.
abstract final class ComponentHealthThresholds {
  /// Ambang batas zona aman.
  /// Persentase sisa > 30% berstatus Aman (Hijau).
  static const double safeThresholdPercent = 30.0;

  /// Ambang batas zona peringatan.
  /// Persentase sisa 10% sampai 30% berstatus Peringatan (Kuning).
  static const double warningThresholdPercent = 10.0;
}

/// Status kesehatan komponen motor
enum ComponentStatus {
  /// > 30%: Hijau (Aman)
  safe,

  /// 10% sampai 30%: Kuning (Peringatan)
  warning,

  /// < 10%: Merah (Batas habis)
  critical;

  /// Teks label status ramah pengguna dalam bahasa Indonesia
  String get label {
    switch (this) {
      case ComponentStatus.safe:
        return 'Aman';
      case ComponentStatus.warning:
        return 'Peringatan';
      case ComponentStatus.critical:
        return 'Batas habis';
    }
  }

  /// Warna indikator utama status sesuai docs/DESIGN.md & docs/SPEC.md bagian 2.1
  Color get color {
    switch (this) {
      case ComponentStatus.safe:
        return AppColors.statusSafeIndicator;
      case ComponentStatus.warning:
        return AppColors.statusWarningIndicator;
      case ComponentStatus.critical:
        return AppColors.statusCriticalIndicator;
    }
  }

  /// Warna latar belakang (container) untuk badge status
  Color get backgroundColor {
    switch (this) {
      case ComponentStatus.safe:
        return AppColors.statusSafeBg;
      case ComponentStatus.warning:
        return AppColors.statusWarningBg;
      case ComponentStatus.critical:
        return AppColors.statusCriticalBg;
    }
  }

  /// Warna teks label pada badge status
  Color get textColor {
    switch (this) {
      case ComponentStatus.safe:
        return AppColors.statusSafeText;
      case ComponentStatus.warning:
        return AppColors.statusWarningText;
      case ComponentStatus.critical:
        return AppColors.statusCriticalText;
    }
  }
}

/// Hasil perhitungan evaluasi kesehatan komponen
class ComponentHealth {
  const ComponentHealth({
    required this.usedKm,
    required this.remainingKm,
    required this.remainingPercentage,
    required this.usedPercentage,
    required this.status,
  });

  /// Jarak yang telah ditempuh sejak servis terakhir (dalam kilometer).
  final int usedKm;

  /// Sisa kilometer sebelum servis berikutnya (dalam kilometer).
  /// Bernilai negatif bila jarak tempuh melebihi batas interval.
  final int remainingKm;

  /// Persentase sisa usia pakai komponen (0.0 sampai 100.0).
  final double remainingPercentage;

  /// Persentase pemakaian komponen yang telah terpakai (0.0 sampai 100.0).
  final double usedPercentage;

  /// Status semantik kondisi komponen (Aman, Peringatan, atau Batas habis).
  final ComponentStatus status;

  /// Teks status ramah pengguna
  String get statusLabel => status.label;

  /// Warna indikator komponen
  Color get color => status.color;

  /// Warna latar belakang badge
  Color get backgroundColor => status.backgroundColor;

  /// Warna teks badge
  Color get textColor => status.textColor;
}

/// Menghitung jarak yang telah ditempuh sejak servis terakhir.
/// Rumus: km_terpakai = km_sekarang - km_servis_terakhir
int calculateUsedKm({
  required int currentKm,
  required int lastServiceKm,
}) {
  return currentKm - lastServiceKm;
}

/// Menghitung sisa kilometer pemakaian komponen.
/// Rumus: sisa_km = interval - km_terpakai
int calculateRemainingKm({
  required int intervalKm,
  required int currentKm,
  required int lastServiceKm,
}) {
  final usedKm = calculateUsedKm(
    currentKm: currentKm,
    lastServiceKm: lastServiceKm,
  );
  return intervalKm - usedKm;
}

/// Menghitung persentase sisa usia pakai komponen (0.0% sampai 100.0%).
/// Rumus: persen = clamp(sisa_km / interval, 0, 1) × 100
/// Menangani batas interval nol atau negatif dengan aman tanpa error division-by-zero.
double calculateRemainingPercentage({
  required int intervalKm,
  required int currentKm,
  required int lastServiceKm,
}) {
  if (intervalKm <= 0) {
    return 0.0;
  }

  final remainingKm = calculateRemainingKm(
    intervalKm: intervalKm,
    currentKm: currentKm,
    lastServiceKm: lastServiceKm,
  );

  final ratio = (remainingKm / intervalKm).clamp(0.0, 1.0);
  return ratio * 100.0;
}

/// Menentukan status kesehatan berdasarkan persentase sisa:
/// - > 30% : Aman (Hijau)
/// - 10% sampai 30% : Peringatan (Kuning)
/// - < 10% : Batas habis (Merah)
ComponentStatus determineComponentStatus(double remainingPercentage) {
  if (remainingPercentage > ComponentHealthThresholds.safeThresholdPercent) {
    return ComponentStatus.safe;
  } else if (remainingPercentage >= ComponentHealthThresholds.warningThresholdPercent) {
    return ComponentStatus.warning;
  } else {
    return ComponentStatus.critical;
  }
}

/// Menghitung seluruh metrik kesehatan komponen secara lengkap
/// berdasarkan KM saat ini, KM servis terakhir, dan interval servis komponen.
ComponentHealth calculateComponentHealth({
  required int intervalKm,
  required int currentKm,
  required int lastServiceKm,
}) {
  final usedKm = calculateUsedKm(
    currentKm: currentKm,
    lastServiceKm: lastServiceKm,
  );

  final remainingKm = calculateRemainingKm(
    intervalKm: intervalKm,
    currentKm: currentKm,
    lastServiceKm: lastServiceKm,
  );

  final remainingPercentage = calculateRemainingPercentage(
    intervalKm: intervalKm,
    currentKm: currentKm,
    lastServiceKm: lastServiceKm,
  );

  final usedPercentage = (100.0 - remainingPercentage).clamp(0.0, 100.0);
  final status = determineComponentStatus(remainingPercentage);

  return ComponentHealth(
    usedKm: usedKm,
    remainingKm: remainingKm,
    remainingPercentage: remainingPercentage,
    usedPercentage: usedPercentage,
    status: status,
  );
}
