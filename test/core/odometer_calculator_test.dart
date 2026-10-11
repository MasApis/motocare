import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/odometer_calculator.dart';

void main() {
  group('calculateDailyAverageKm - SPEC 2.1 & F4', () {
    final refDate = DateTime(2026, 10, 15);

    test('Data kosong: mengembalikan nilai default 20.0 km/hari', () {
      final result = calculateDailyAverageKm([], referenceDate: refDate);
      expect(result, equals(kDefaultDailyAverageKm));
      expect(result, equals(20.0));
    });

    test('Data hanya 1 catatan (data kurang): mengembalikan nilai default 20.0 km/hari', () {
      final entries = [
        OdometerEntry(km: 10000, date: DateTime(2026, 10, 10)),
      ];
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(20.0));
    });

    test('Data di luar rentang 30 hari terakhir (data kurang): mengembalikan default 20.0 km/hari', () {
      final entries = [
        // 45 hari yang lalu
        OdometerEntry(km: 8000, date: DateTime(2026, 8, 30)),
        // 40 hari yang lalu
        OdometerEntry(km: 8500, date: DateTime(2026, 9, 4)),
      ];
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(20.0));
    });

    test('Hanya 1 entri dalam 30 hari (1 entri lainnya sudah kadaluarsa): mengembalikan 20.0 km/hari', () {
      final entries = [
        // 40 hari lalu (di luar 30 hari)
        OdometerEntry(km: 8000, date: DateTime(2026, 9, 1)),
        // 5 hari lalu (dalam 30 hari)
        OdometerEntry(km: 9000, date: DateTime(2026, 10, 10)),
      ];
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(20.0));
    });

    test('Selisih hari < 3 (misal sama hari / 0 hari): mengembalikan nilai default 20.0 km/hari', () {
      final entries = [
        OdometerEntry(km: 10000, date: DateTime(2026, 10, 10)),
        OdometerEntry(km: 10025, date: DateTime(2026, 10, 10)),
      ];
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(20.0));
    });

    test('Selisih hari < 3 (misal selisih 1 hari): mengembalikan nilai default 20.0 km/hari', () {
      final entries = [
        OdometerEntry(km: 10000, date: DateTime(2026, 10, 10)),
        OdometerEntry(km: 10035, date: DateTime(2026, 10, 11)),
      ];
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(20.0));
    });

    test('Selisih hari < 3 (misal selisih 2 hari): mengembalikan nilai default 20.0 km/hari', () {
      final entries = [
        OdometerEntry(km: 10000, date: DateTime(2026, 10, 10)),
        OdometerEntry(km: 10060, date: DateTime(2026, 10, 12)),
      ];
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(20.0));
    });

    test('Data normal: selisih tepat 3 hari menghitung (km baru - km lama) / selisih hari', () {
      final entries = [
        OdometerEntry(km: 10000, date: DateTime(2026, 10, 10)),
        OdometerEntry(km: 10075, date: DateTime(2026, 10, 13)), // 75 km dalam 3 hari
      ];
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      // (10075 - 10000) / 3 = 75 / 3 = 25.0 km/hari
      expect(result, equals(25.0));
    });

    test('Data normal: banyak entri dalam 30 hari, menghitung dari tertua ke terbaru dalam rentang', () {
      final entries = [
        OdometerEntry(km: 10000, date: DateTime(2026, 9, 25)), // 20 hari sebelum refDate
        OdometerEntry(km: 10100, date: DateTime(2026, 10, 1)),
        OdometerEntry(km: 10250, date: DateTime(2026, 10, 5)),
        OdometerEntry(km: 10500, date: DateTime(2026, 10, 15)), // tepat refDate
      ];
      // Rentang: 25 Sep ke 15 Okt = 20 hari
      // Selisih km: 10500 - 10000 = 500 km
      // Rata-rata: 500 / 20 = 25.0 km/hari
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(25.0));
    });

    test('Data tidak berurutan secara waktu tetap diurutkan dengan benar', () {
      final entries = [
        OdometerEntry(km: 10600, date: DateTime(2026, 10, 10)), // selisih 10 hari
        OdometerEntry(km: 10000, date: DateTime(2026, 9, 30)),
      ];
      // Selisih hari: 10 hari. KM: 600. Rata-rata: 60 km/hari
      final result = calculateDailyAverageKm(entries, referenceDate: refDate);
      expect(result, equals(60.0));
    });

    test('formatDailyAverageKm memformat angka dengan "± X km/hari"', () {
      expect(formatDailyAverageKm(20.0), equals('± 20 km/hari'));
      expect(formatDailyAverageKm(25.4), equals('± 25 km/hari'));
      expect(formatDailyAverageKm(21.8), equals('± 22 km/hari'));
    });
  });
}
