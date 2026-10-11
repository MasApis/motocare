import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/component_health.dart';
import 'package:motocare/core/service_calculator.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ServiceCalculator - Reset & Logika Servis Baru', () {
    test('calculateNewLastServiceKm mengembalikan KM servis yang baru diinput', () {
      final newLastKm = ServiceCalculator.calculateNewLastServiceKm(serviceKm: 15000);
      expect(newLastKm, 15000);
    });

    test('calculateNewLastServiceKm menjaga nilai non-negatif', () {
      final newLastKm = ServiceCalculator.calculateNewLastServiceKm(serviceKm: -500);
      expect(newLastKm, 0);
    });

    test('Kartu kembali 100% setelah servis baru dicatat pada KM sekarang', () {
      const currentKm = 15000;
      const intervalKm = 2000;
      // Servis dicatat di currentKm
      final newLastServiceKm = ServiceCalculator.calculateNewLastServiceKm(
        serviceKm: currentKm,
      );

      final health = calculateComponentHealth(
        intervalKm: intervalKm,
        currentKm: currentKm,
        lastServiceKm: newLastServiceKm,
      );

      // Kartu kembali 100% (sisa 100%, terpakai 0%, status aman)
      expect(health.remainingPercentage, 100.0);
      expect(health.usedPercentage, 0.0);
      expect(health.usedKm, 0);
      expect(health.remainingKm, intervalKm);
      expect(health.status, ComponentStatus.safe);
    });
  });

  group('ServiceCalculator - Hapus Catatan Servis & Perhitungan Mundur', () {
    test('calculateLastServiceKmAfterDelete kembali ke servis sebelumnya saat masih ada servis tersisa', () {
      const initialKm = 10000;
      // Riwayat servis: Servis 1 di 12.000 KM, Servis 2 di 14.000 KM, Servis 3 di 16.000 KM
      // Ketika Servis 3 (16.000 KM) dihapus, yang tersisa adalah [12.000, 14.000]
      final remainingKms = [12000, 14000];

      final lastKm = ServiceCalculator.calculateLastServiceKmAfterDelete(
        initialKm: initialKm,
        remainingServiceKms: remainingKms,
      );

      expect(lastKm, 14000);
    });

    test('calculateLastServiceKmAfterDelete memilih KM terbesar jika urutan array acak', () {
      const initialKm = 5000;
      final remainingKms = [8000, 11000, 9500];

      final lastKm = ServiceCalculator.calculateLastServiceKmAfterDelete(
        initialKm: initialKm,
        remainingServiceKms: remainingKms,
      );

      expect(lastKm, 11000);
    });

    test('calculateLastServiceKmAfterDelete kembali ke baseline initialKm ketika semua servis dihapus', () {
      const initialKm = 10000;
      final remainingKms = <int>[]; // Kosong karena seluruh servis telah dihapus

      final lastKm = ServiceCalculator.calculateLastServiceKmAfterDelete(
        initialKm: initialKm,
        remainingServiceKms: remainingKms,
      );

      expect(lastKm, initialKm);
    });

    test('calculateLastServiceKmAfterDelete menjaga nilai baseline tetap non-negatif', () {
      const initialKm = -100;
      final remainingKms = <int>[];

      final lastKm = ServiceCalculator.calculateLastServiceKmAfterDelete(
        initialKm: initialKm,
        remainingServiceKms: remainingKms,
      );

      expect(lastKm, 0);
    });

    test('Kartu menghitung ulang secara presisi dari servis sebelumnya setelah servis terakhir dihapus', () {
      // Skenario nyata:
      // Odometer sekarang 15.000 KM, Interval oli 2.000 KM
      // Servis 1: 12.000 KM
      // Servis 2: 14.500 KM (Kondisi saat ini: used = 500 KM, remaining = 1.500 KM)
      // Pengguna menghapus Servis 2 (salah catat)
      // Kartu harus kembali menghitung dari Servis 1 (12.000 KM)
      const currentKm = 15000;
      const intervalKm = 2000;
      const initialKm = 10000;

      final remainingAfterDelete = [12000];
      final revertedLastKm = ServiceCalculator.calculateLastServiceKmAfterDelete(
        initialKm: initialKm,
        remainingServiceKms: remainingAfterDelete,
      );

      expect(revertedLastKm, 12000);

      // Hitung kesehatan setelah dihapus:
      // Pemakaian dari 12.000 ke 15.000 = 3.000 KM (melebihi interval 2.000 KM)
      final health = calculateComponentHealth(
        intervalKm: intervalKm,
        currentKm: currentKm,
        lastServiceKm: revertedLastKm,
      );

      expect(health.usedKm, 3000);
      expect(health.remainingKm, -1000);
      expect(health.remainingPercentage, 0.0);
      expect(health.status, ComponentStatus.critical);
    });
  });

  group('ServiceCalculator - Format Rupiah & Tanggal Indonesia', () {
    test('formatRupiah memformat angka menjadi format mata uang Indonesia', () {
      expect(ServiceCalculator.formatRupiah(145000), 'Rp 145.000');
      expect(ServiceCalculator.formatRupiah(0), 'Rp 0');
      expect(ServiceCalculator.formatRupiah(2500000), 'Rp 2.500.000');
    });

    test('formatDate memformat tanggal sesuai singkatan bulan Indonesia', () {
      final date = DateTime(2025, 3, 15);
      final formatted = ServiceCalculator.formatDate(date);
      expect(formatted, contains('15'));
      expect(formatted, contains('2025'));
    });

    test('formatFullDate memformat tanggal lengkap Indonesia', () {
      final date = DateTime(2025, 3, 15);
      final formatted = ServiceCalculator.formatFullDate(date);
      expect(formatted, contains('15'));
      expect(formatted, contains('Maret'));
      expect(formatted, contains('2025'));
    });

    test('parseRupiahInput mengurai teks rupiah dengan berbagai variasi ke integer', () {
      expect(ServiceCalculator.parseRupiahInput('145.000'), 145000);
      expect(ServiceCalculator.parseRupiahInput('Rp 145.000'), 145000);
      expect(ServiceCalculator.parseRupiahInput('Rp145000'), 145000);
      expect(ServiceCalculator.parseRupiahInput('50000'), 50000);
      expect(ServiceCalculator.parseRupiahInput(''), isNull);
      expect(ServiceCalculator.parseRupiahInput('   '), isNull);
      expect(ServiceCalculator.parseRupiahInput('abc'), isNull);
      expect(ServiceCalculator.parseRupiahInput(null), isNull);
    });

    test('formatKm memformat angka kilometer dengan titik pemisah ribuan', () {
      expect(ServiceCalculator.formatKm(14280), '14.280');
      expect(ServiceCalculator.formatKm(0), '0');
      expect(ServiceCalculator.formatKm(100000), '100.000');
    });
  });
}
