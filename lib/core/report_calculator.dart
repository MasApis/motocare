import 'package:intl/intl.dart';
import '../features/service/data/models/service_record_model.dart';
import 'service_calculator.dart';

/// Fungsi-fungsi murni untuk perhitungan dan pemfilteran laporan bulanan
/// sesuai dengan docs/SPEC.md bagian 5 (F8).
abstract final class ReportCalculator {
  /// Menyaring daftar [records] hanya untuk bulan dan tahun yang sama dengan [targetMonth].
  static List<ServiceRecord> filterByMonth(
    List<ServiceRecord> records,
    DateTime targetMonth,
  ) {
    return records.where((record) {
      return record.date.year == targetMonth.year &&
          record.date.month == targetMonth.month;
    }).toList();
  }

  /// Menghitung total biaya pengeluaran dari daftar [records].
  /// Seluruh harga dijumlahkan (jika negatif, diabaikan atau dianggap 0).
  static int calculateTotalExpense(List<ServiceRecord> records) {
    if (records.isEmpty) return 0;
    int total = 0;
    for (final record in records) {
      if (record.price > 0) {
        total += record.price;
      }
    }
    return total;
  }

  /// Menghasilkan nama bulan dalam bahasa Indonesia (id_ID),
  /// contoh: DateTime(2025, 9, 1) -> "September"
  static String formatMonthName(DateTime date) {
    try {
      final formatter = DateFormat('MMMM', 'id_ID');
      return formatter.format(date);
    } catch (_) {
      final formatter = DateFormat('MMMM');
      return formatter.format(date);
    }
  }

  /// Menghasilkan format bulan dan tahun dalam bahasa Indonesia (id_ID),
  /// contoh: DateTime(2025, 9, 1) -> "September 2025"
  static String formatMonthYear(DateTime date) {
    try {
      final formatter = DateFormat('MMMM yyyy', 'id_ID');
      return formatter.format(date);
    } catch (_) {
      final formatter = DateFormat('MMMM yyyy');
      return formatter.format(date);
    }
  }

  /// Menghasilkan teks ringkasan pengeluaran bulanan sesuai SPEC F8,
  /// contoh: "Pengeluaran September: Rp 150.000"
  static String formatMonthlyExpenseSummary(DateTime month, int totalExpense) {
    final monthName = formatMonthName(month);
    final formattedPrice = ServiceCalculator.formatRupiah(totalExpense);
    return 'Pengeluaran $monthName: $formattedPrice';
  }
}
