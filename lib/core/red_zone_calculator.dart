import 'odometer_calculator.dart';

/// Ambang batas persentase sisa kilometer untuk zona merah (< 10%)
const double kRedZoneThresholdPercent = 10.0;

/// Menghitung jarak tempuh yang tersisa sebelum komponen masuk ke zona merah (< 10% interval).
///
/// Rumus:
/// `km_menuju_merah = sisa_km - (10% * interval)`
/// Jika hasil <= 0, komponen sudah berada di zona merah (atau pas batas merah).
double calculateKmToRedZone({
  required int intervalKm,
  required int currentKm,
  required int lastServiceKm,
}) {
  final usedKm = currentKm - lastServiceKm;
  final remainingKm = intervalKm - usedKm;
  final redZoneKmThreshold = 0.10 * intervalKm;
  return remainingKm - redZoneKmThreshold;
}

/// Menghitung perkiraan selisih hari sampai komponen masuk ke zona merah.
///
/// Mengembalikan 0 jika komponen sudah berada di zona merah (< 10% sisa).
/// Jika rata-rata harian <= 0, otomatis menggunakan nilai default [kDefaultDailyAverageKm] (20 km/hari).
int calculateDaysToRedZone({
  required int intervalKm,
  required int currentKm,
  required int lastServiceKm,
  required double dailyAverageKm,
}) {
  final kmToRed = calculateKmToRedZone(
    intervalKm: intervalKm,
    currentKm: currentKm,
    lastServiceKm: lastServiceKm,
  );

  // Jika sisa km menuju zona merah sudah <= 0, berarti sudah masuk zona merah hari ini
  if (kmToRed <= 0) {
    return 0;
  }

  final effectiveAvg = dailyAverageKm > 0 ? dailyAverageKm : kDefaultDailyAverageKm;
  // Gunakan ceil agar estimasi hari tidak jatuh sebelum komponen benar-benar mencapai batas
  return (kmToRed / effectiveAvg).ceil();
}

/// Menghitung estimasi tanggal kalender masuk zona merah sesuai docs/SPEC.md bagian 2.1:
/// "hari ini + ((sisa_km - 10% * interval) / rata2_harian) hari. Jika sudah merah, dianggap hari ini."
///
/// Hasil dinormalisasi ke tanggal kalender murni (jam 00:00:00).
DateTime calculateRedZoneDate({
  required int intervalKm,
  required int currentKm,
  required int lastServiceKm,
  required double dailyAverageKm,
  DateTime? referenceDate,
}) {
  final now = referenceDate ?? DateTime.now();
  final baseDate = DateTime(now.year, now.month, now.day);

  final days = calculateDaysToRedZone(
    intervalKm: intervalKm,
    currentKm: currentKm,
    lastServiceKm: lastServiceKm,
    dailyAverageKm: dailyAverageKm,
  );

  if (days <= 0) {
    return baseDate;
  }

  return baseDate.add(Duration(days: days));
}
