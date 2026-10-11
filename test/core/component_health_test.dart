import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/component_health.dart';
import 'package:motocare/core/vehicle_components.dart';
import 'package:motocare/shared/theme/app_colors.dart';

void main() {
  group('ComponentHealthThresholds', () {
    test('ambang batas terdefinisi di satu tempat sesuai SPEC bagian 2.1', () {
      expect(ComponentHealthThresholds.safeThresholdPercent, 30.0);
      expect(ComponentHealthThresholds.warningThresholdPercent, 10.0);
    });
  });

  group('calculateUsedKm', () {
    test('menghitung km terpakai dengan benar', () {
      // km_terpakai = km_sekarang - km_servis_terakhir
      expect(
        calculateUsedKm(currentKm: 15000, lastServiceKm: 14000),
        1000,
      );
      expect(
        calculateUsedKm(currentKm: 14000, lastServiceKm: 14000),
        0,
      );
    });
  });

  group('calculateRemainingKm', () {
    test('menghitung sisa km dengan benar', () {
      // sisa_km = interval - km_terpakai
      expect(
        calculateRemainingKm(
          intervalKm: 2000,
          currentKm: 15000,
          lastServiceKm: 14000,
        ),
        1000,
      );
    });

    test('menghasilkan nilai negatif saat KM melebihi interval', () {
      // Interval 2.000 km, terpakai 2.500 km -> sisa -500 km
      final remaining = calculateRemainingKm(
        intervalKm: 2000,
        currentKm: 16500,
        lastServiceKm: 14000,
      );
      expect(remaining, -500);
    });
  });

  group('calculateRemainingPercentage', () {
    test('mengembalikan 100% saat motor baru diservis (currentKm == lastServiceKm)', () {
      final percentage = calculateRemainingPercentage(
        intervalKm: 2000,
        currentKm: 10000,
        lastServiceKm: 10000,
      );
      expect(percentage, 100.0);
    });

    test('mengembalikan 50% saat separuh interval terpakai', () {
      final percentage = calculateRemainingPercentage(
        intervalKm: 2000,
        currentKm: 11000,
        lastServiceKm: 10000,
      );
      expect(percentage, 50.0);
    });

    test('kasus batas tepat 0%: sisa km habis (currentKm - lastServiceKm == interval)', () {
      final percentage = calculateRemainingPercentage(
        intervalKm: 2000,
        currentKm: 12000,
        lastServiceKm: 10000,
      );
      expect(percentage, 0.0);
    });

    test('kasus batas KM melebihi interval: tetap diclamp ke 0.0%', () {
      final percentage = calculateRemainingPercentage(
        intervalKm: 2000,
        currentKm: 13500,
        lastServiceKm: 10000,
      );
      expect(percentage, 0.0);
    });

    test('kasus batas interval nol: mengembalikan 0.0% tanpa error pembagian nol', () {
      final percentage = calculateRemainingPercentage(
        intervalKm: 0,
        currentKm: 10000,
        lastServiceKm: 10000,
      );
      expect(percentage, 0.0);
    });

    test('kasus batas interval negatif: mengembalikan 0.0%', () {
      final percentage = calculateRemainingPercentage(
        intervalKm: -500,
        currentKm: 10000,
        lastServiceKm: 10000,
      );
      expect(percentage, 0.0);
    });
  });

  group('determineComponentStatus', () {
    test('status Aman (> 30%)', () {
      expect(determineComponentStatus(100.0), ComponentStatus.safe);
      expect(determineComponentStatus(50.0), ComponentStatus.safe);
      expect(determineComponentStatus(30.01), ComponentStatus.safe);
    });

    test('kasus batas 30%: tepat 30.0% masuk zona Peringatan', () {
      // 10% sampai 30% adalah Peringatan
      expect(determineComponentStatus(30.0), ComponentStatus.warning);
    });

    test('status Peringatan (10% sampai 30%)', () {
      expect(determineComponentStatus(29.9), ComponentStatus.warning);
      expect(determineComponentStatus(20.0), ComponentStatus.warning);
      expect(determineComponentStatus(10.01), ComponentStatus.warning);
    });

    test('kasus batas 10%: tepat 10.0% masuk zona Peringatan', () {
      // 10% sampai 30% adalah Peringatan
      expect(determineComponentStatus(10.0), ComponentStatus.warning);
    });

    test('status Batas habis (< 10%)', () {
      expect(determineComponentStatus(9.99), ComponentStatus.critical);
      expect(determineComponentStatus(5.0), ComponentStatus.critical);
      expect(determineComponentStatus(0.01), ComponentStatus.critical);
    });

    test('kasus batas 0%: tepat 0.0% masuk status Batas habis', () {
      expect(determineComponentStatus(0.0), ComponentStatus.critical);
    });
  });

  group('ComponentStatus label dan warna', () {
    test('memiliki teks status bahasa Indonesia yang ramah (penanda bukan hanya warna)', () {
      expect(ComponentStatus.safe.label, 'Aman');
      expect(ComponentStatus.warning.label, 'Peringatan');
      expect(ComponentStatus.critical.label, 'Batas habis');
    });

    test('memiliki warna indikator sesuai panduan SPEC & DESIGN.md', () {
      expect(ComponentStatus.safe.color, AppColors.statusSafeIndicator);
      expect(ComponentStatus.warning.color, AppColors.statusWarningIndicator);
      expect(ComponentStatus.critical.color, AppColors.statusCriticalIndicator);
    });

    test('memiliki warna latar belakang dan teks kontras untuk badge', () {
      expect(ComponentStatus.safe.backgroundColor, AppColors.statusSafeBg);
      expect(ComponentStatus.safe.textColor, AppColors.statusSafeText);

      expect(ComponentStatus.warning.backgroundColor, AppColors.statusWarningBg);
      expect(ComponentStatus.warning.textColor, AppColors.statusWarningText);

      expect(ComponentStatus.critical.backgroundColor, AppColors.statusCriticalBg);
      expect(ComponentStatus.critical.textColor, AppColors.statusCriticalText);
    });
  });

  group('calculateComponentHealth komprehensif', () {
    test('mengevaluasi oli mesin dengan batas interval default 2.000 km', () {
      // Misal Oli mesin: interval 2000, diservis di KM 10.000, sekarang 11.200 (sisa 800 km, 40%)
      final health = calculateComponentHealth(
        intervalKm: DefaultIntervals.engineOil,
        currentKm: 11200,
        lastServiceKm: 10000,
      );

      expect(health.usedKm, 1200);
      expect(health.remainingKm, 800);
      expect(health.remainingPercentage, 40.0);
      expect(health.usedPercentage, 60.0);
      expect(health.status, ComponentStatus.safe);
      expect(health.statusLabel, 'Aman');
      expect(health.color, AppColors.statusSafeIndicator);
    });

    test('mengevaluasi oli gardan pada batas zona peringatan (sisa 25% = 2.000 km dari 8.000 km)', () {
      final health = calculateComponentHealth(
        intervalKm: DefaultIntervals.gearOil, // 8.000 km
        currentKm: 16000,
        lastServiceKm: 10000, // terpakai 6.000 km, sisa 2.000 km (25%)
      );

      expect(health.usedKm, 6000);
      expect(health.remainingKm, 2000);
      expect(health.remainingPercentage, 25.0);
      expect(health.usedPercentage, 75.0);
      expect(health.status, ComponentStatus.warning);
      expect(health.statusLabel, 'Peringatan');
      expect(health.color, AppColors.statusWarningIndicator);
    });

    test('mengevaluasi V-belt pada zona batas habis (< 10% = sisa 1.000 km dari 20.000 km = 5%)', () {
      final health = calculateComponentHealth(
        intervalKm: DefaultIntervals.vBelt, // 20.000 km
        currentKm: 29000,
        lastServiceKm: 10000, // terpakai 19.000 km, sisa 1.000 km (5%)
      );

      expect(health.usedKm, 19000);
      expect(health.remainingKm, 1000);
      expect(health.remainingPercentage, 5.0);
      expect(health.usedPercentage, 95.0);
      expect(health.status, ComponentStatus.critical);
      expect(health.statusLabel, 'Batas habis');
      expect(health.color, AppColors.statusCriticalIndicator);
    });

    test('mengevaluasi saat KM melebihi interval: sisa km negatif, persen sisa 0%, status Batas habis', () {
      final health = calculateComponentHealth(
        intervalKm: 2000,
        currentKm: 13000,
        lastServiceKm: 10000, // terpakai 3.000 km (> 2.000 km)
      );

      expect(health.usedKm, 3000);
      expect(health.remainingKm, -1000);
      expect(health.remainingPercentage, 0.0);
      expect(health.usedPercentage, 100.0);
      expect(health.status, ComponentStatus.critical);
      expect(health.statusLabel, 'Batas habis');
    });

    test('mengevaluasi saat interval nol: tidak crash, persen sisa 0%, status Batas habis', () {
      final health = calculateComponentHealth(
        intervalKm: 0,
        currentKm: 10500,
        lastServiceKm: 10000,
      );

      expect(health.remainingKm, -500);
      expect(health.remainingPercentage, 0.0);
      expect(health.usedPercentage, 100.0);
      expect(health.status, ComponentStatus.critical);
      expect(health.statusLabel, 'Batas habis');
    });
  });
}
