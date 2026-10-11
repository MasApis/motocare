/// Logika murni perhitungan odometer dan rata-rata KM harian sesuai docs/SPEC.md bagian 2.1
library;

/// Nilai default asumsi rata-rata KM harian jika data belum mencukupi
const double kDefaultDailyAverageKm = 20.0;

/// Ambang minimal selisih hari antar catatan untuk menghitung rata-rata harian
const int kMinDaysDifferenceForAverage = 3;

/// Rentang waktu pencatatan yang diperhitungkan (30 hari terakhir)
const int kOdometerLookbackDays = 30;

/// Model data murni entri odometer untuk kalkulasi di core
class OdometerEntry {
  const OdometerEntry({
    required this.km,
    required this.date,
  });

  final int km;
  final DateTime date;
}

/// Menghitung selisih hari kalender murni antara dua tanggal
int calendarDaysDifference(DateTime from, DateTime to) {
  final fromDate = DateTime(from.year, from.month, from.day);
  final toDate = DateTime(to.year, to.month, to.day);
  return toDate.difference(fromDate).inDays;
}

/// Menghitung rata-rata KM harian dari catatan odometer sesuai docs/SPEC.md bagian 2.1:
/// - Dari catatan odometer 30 hari terakhir: `(km terbaru - km tertua) / selisih hari`
/// - Dibutuhkan minimal dua catatan dengan selisih ≥ 3 hari
/// - Jika tidak memenuhi, gunakan nilai awal 20 km/hari
double calculateDailyAverageKm(
  List<OdometerEntry> entries, {
  DateTime? referenceDate,
}) {
  if (entries.length < 2) {
    return kDefaultDailyAverageKm;
  }

  final now = referenceDate ?? DateTime.now();
  final nowDate = DateTime(now.year, now.month, now.day);
  final cutoffDate = nowDate.subtract(const Duration(days: kOdometerLookbackDays));

  // Filter hanya entri dalam 30 hari terakhir dan tidak di masa depan
  final recentEntries = entries.where((entry) {
    final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
    return !entryDate.isBefore(cutoffDate) && !entryDate.isAfter(nowDate);
  }).toList();

  if (recentEntries.length < 2) {
    return kDefaultDailyAverageKm;
  }

  // Urutkan entri berdasarkan tanggal (lama -> baru), lalu KM jika tanggal sama
  recentEntries.sort((a, b) {
    final dateComp = a.date.compareTo(b.date);
    if (dateComp != 0) return dateComp;
    return a.km.compareTo(b.km);
  });

  final oldest = recentEntries.first;
  final newest = recentEntries.last;

  final daysDiff = calendarDaysDifference(oldest.date, newest.date);
  if (daysDiff < kMinDaysDifferenceForAverage) {
    return kDefaultDailyAverageKm;
  }

  final kmDiff = newest.km - oldest.km;
  if (kmDiff < 0) {
    // Anomali data (KM turun)
    return kDefaultDailyAverageKm;
  }

  return kmDiff / daysDiff;
}

/// Format tampilan string rata-rata harian sesuai SPEC (misal "± 25 km/hari")
String formatDailyAverageKm(double avgKm) {
  final rounded = avgKm.round();
  return '± $rounded km/hari';
}
