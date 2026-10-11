import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/red_zone_calculator.dart';

void main() {
  group('RedZoneCalculator Tests', () {
    final referenceDate = DateTime(2026, 10, 12);

    test('calculateKmToRedZone mengembalikan km positif jika belum merah', () {
      // Oli mesin: interval 2000 km, last 0 km, current 1000 km
      // sisa = 1000 km. Batas 10% = 200 km.
      // km to red = 1000 - 200 = 800 km
      final kmToRed = calculateKmToRedZone(
        intervalKm: 2000,
        currentKm: 1000,
        lastServiceKm: 0,
      );
      expect(kmToRed, equals(800.0));
    });

    test('calculateKmToRedZone mengembalikan 0 jika tepat pada ambang 10%', () {
      // Oli mesin: interval 2000 km, last 0 km, current 1800 km
      // sisa = 200 km (10%). Batas 10% = 200 km.
      // km to red = 200 - 200 = 0 km
      final kmToRed = calculateKmToRedZone(
        intervalKm: 2000,
        currentKm: 1800,
        lastServiceKm: 0,
      );
      expect(kmToRed, equals(0.0));
    });

    test('calculateKmToRedZone mengembalikan negatif jika sudah lewat 10% atau melebihi interval', () {
      // Oli mesin: current 1900 km, sisa 100 km (5%)
      final kmToRed = calculateKmToRedZone(
        intervalKm: 2000,
        currentKm: 1900,
        lastServiceKm: 0,
      );
      expect(kmToRed, equals(-100.0));

      // Overdue: current 2100 km
      final overdueKmToRed = calculateKmToRedZone(
        intervalKm: 2000,
        currentKm: 2100,
        lastServiceKm: 0,
      );
      expect(overdueKmToRed, equals(-300.0));
    });

    test('calculateDaysToRedZone mengembalikan 0 hari jika komponen sudah merah', () {
      final days = calculateDaysToRedZone(
        intervalKm: 2000,
        currentKm: 1850,
        lastServiceKm: 0,
        dailyAverageKm: 20.0,
      );
      expect(days, equals(0));
    });

    test('calculateDaysToRedZone menghitung hari dengan benar menggunakan ceil', () {
      // interval 2000, current 1600, last 0.
      // sisa = 400. Batas 10% = 200. km to red = 200 km.
      // dailyAverage = 20 km/hari -> 200 / 20 = 10 hari
      final days = calculateDaysToRedZone(
        intervalKm: 2000,
        currentKm: 1600,
        lastServiceKm: 0,
        dailyAverageKm: 20.0,
      );
      expect(days, equals(10));

      // Jika dailyAverage = 25 km/hari dan kmToRed = 210 km -> 210 / 25 = 8.4 -> ceil = 9 hari
      final daysFraction = calculateDaysToRedZone(
        intervalKm: 2000,
        currentKm: 1590, // sisa 410, kmToRed = 210
        lastServiceKm: 0,
        dailyAverageKm: 25.0,
      );
      expect(daysFraction, equals(9));
    });

    test('calculateDaysToRedZone fallback ke default 20 km/hari jika dailyAverage <= 0', () {
      // km to red = 200 km. Jika dailyAverage = 0 -> pakai 20 km/hari -> 10 hari
      final days = calculateDaysToRedZone(
        intervalKm: 2000,
        currentKm: 1600,
        lastServiceKm: 0,
        dailyAverageKm: 0.0,
      );
      expect(days, equals(10));
    });

    test('calculateRedZoneDate mengembalikan hari ini jika komponen sudah merah', () {
      final redZoneDate = calculateRedZoneDate(
        intervalKm: 2000,
        currentKm: 1900,
        lastServiceKm: 0,
        dailyAverageKm: 25.0,
        referenceDate: referenceDate,
      );
      expect(redZoneDate, equals(DateTime(2026, 10, 12)));
    });

    test('calculateRedZoneDate mengembalikan tanggal masa depan yang tepat', () {
      // 10 hari dari 2026-10-12 -> 2026-10-22
      final redZoneDate = calculateRedZoneDate(
        intervalKm: 2000,
        currentKm: 1600,
        lastServiceKm: 0,
        dailyAverageKm: 20.0,
        referenceDate: referenceDate,
      );
      expect(redZoneDate, equals(DateTime(2026, 10, 22)));
    });
  });
}
