import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/report_calculator.dart';
import 'package:motocare/features/service/data/models/service_record_model.dart';

ServiceRecord _createRecord({
  required String id,
  required DateTime date,
  required int price,
  String componentType = 'engine_oil',
  int km = 10000,
  String brand = 'SPX2',
  String location = 'AHASS Jaya',
}) {
  return ServiceRecord(
    id: id,
    vehicleId: 'v1',
    componentType: componentType,
    date: date,
    km: km,
    brand: brand,
    price: price,
    location: location,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ReportCalculator - filterByMonth', () {
    test('mengembalikan list kosong jika input records kosong', () {
      final result = ReportCalculator.filterByMonth([], DateTime(2025, 9, 1));
      expect(result, isEmpty);
    });

    test('hanya menyaring catatan pada bulan dan tahun yang cocok', () {
      final records = [
        _createRecord(id: '1', date: DateTime(2025, 9, 2), price: 100000),
        _createRecord(id: '2', date: DateTime(2025, 9, 28), price: 50000),
        _createRecord(id: '3', date: DateTime(2025, 8, 15), price: 75000),
        _createRecord(id: '4', date: DateTime(2024, 9, 10), price: 80000),
        _createRecord(id: '5', date: DateTime(2025, 10, 1), price: 60000),
      ];

      final filtered = ReportCalculator.filterByMonth(records, DateTime(2025, 9, 15));

      expect(filtered.length, 2);
      expect(filtered.map((r) => r.id), containsAll(['1', '2']));
      expect(filtered.map((r) => r.id), isNot(contains('3')));
      expect(filtered.map((r) => r.id), isNot(contains('4')));
      expect(filtered.map((r) => r.id), isNot(contains('5')));
    });

    test('mengembalikan list kosong jika tidak ada catatan di bulan tersebut', () {
      final records = [
        _createRecord(id: '1', date: DateTime(2025, 8, 15), price: 75000),
      ];

      final filtered = ReportCalculator.filterByMonth(records, DateTime(2025, 9, 1));
      expect(filtered, isEmpty);
    });
  });

  group('ReportCalculator - calculateTotalExpense', () {
    test('mengembalikan 0 jika list kosong', () {
      expect(ReportCalculator.calculateTotalExpense([]), 0);
    });

    test('menghitung jumlah total pengeluaran dengan benar', () {
      final records = [
        _createRecord(id: '1', date: DateTime(2025, 9, 2), price: 100000),
        _createRecord(id: '2', date: DateTime(2025, 9, 15), price: 50000),
        _createRecord(id: '3', date: DateTime(2025, 9, 20), price: 75000),
      ];

      final total = ReportCalculator.calculateTotalExpense(records);
      expect(total, 225000);
    });

    test('mengabaikan harga negatif jika ada data anomali', () {
      final records = [
        _createRecord(id: '1', date: DateTime(2025, 9, 2), price: 100000),
        _createRecord(id: '2', date: DateTime(2025, 9, 5), price: -50000),
        _createRecord(id: '3', date: DateTime(2025, 9, 10), price: 0),
      ];

      final total = ReportCalculator.calculateTotalExpense(records);
      expect(total, 100000);
    });
  });

  group('ReportCalculator - Format Helpers', () {
    test('formatMonthName menghasilkan nama bulan', () {
      final name = ReportCalculator.formatMonthName(DateTime(2025, 9, 1));
      expect(name.toLowerCase(), contains('september'));
    });

    test('formatMonthYear menghasilkan bulan dan tahun', () {
      final str = ReportCalculator.formatMonthYear(DateTime(2025, 9, 1));
      expect(str, contains('September'));
      expect(str, contains('2025'));
    });

    test('formatMonthlyExpenseSummary menghasilkan teks sesuai contoh SPEC F8', () {
      final summary = ReportCalculator.formatMonthlyExpenseSummary(
        DateTime(2025, 9, 1),
        150000,
      );
      // Contoh SPEC: "Pengeluaran September: Rp 150.000"
      expect(summary, contains('Pengeluaran September'));
      expect(summary, contains('150.000'));
    });
  });
}
