import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/report_calculator.dart';
import '../../service/data/models/service_record_model.dart';
import '../../service/providers/service_providers.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../data/pdf_report_generator.dart';

/// Provider generator PDF
final pdfReportGeneratorProvider = Provider<PdfReportGenerator>((ref) {
  return const PdfReportGenerator();
});

/// Notifier untuk mengelola bulan yang dipilih pada Laporan Bulanan (F8)
class SelectedReportMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Pindah ke bulan sebelumnya
  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  /// Pindah ke bulan berikutnya
  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  /// Memilih bulan dan tahun tertentu
  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }

  /// Kembali ke bulan saat ini
  void resetToCurrentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }
}

final selectedReportMonthProvider =
    NotifierProvider<SelectedReportMonthNotifier, DateTime>(
  SelectedReportMonthNotifier.new,
);

/// Provider catatan servis yang telah disaring berdasarkan motor aktif dan bulan terpilih
final monthlyReportRecordsProvider =
    Provider<AsyncValue<List<ServiceRecord>>>((ref) {
  final activeVehicle = ref.watch(selectedVehicleProvider);
  if (activeVehicle == null) {
    return const AsyncValue.data([]);
  }

  final recordsAsync = ref.watch(serviceRecordsStreamProvider(activeVehicle.id));
  final selectedMonth = ref.watch(selectedReportMonthProvider);

  return recordsAsync.whenData((records) {
    return ReportCalculator.filterByMonth(records, selectedMonth);
  });
});

/// Provider total biaya pengeluaran servis pada bulan terpilih
final monthlyReportTotalProvider = Provider<int>((ref) {
  final recordsAsync = ref.watch(monthlyReportRecordsProvider);
  final records = recordsAsync.asData?.value ?? [];
  return ReportCalculator.calculateTotalExpense(records);
});
