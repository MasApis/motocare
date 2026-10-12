import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/features/reports/ui/monthly_report_screen.dart';
import 'package:motocare/features/service/data/models/service_record_model.dart';
import 'package:motocare/features/service/providers/service_providers.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_model.dart';
import 'package:motocare/features/vehicles/providers/vehicle_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testVehicle = Vehicle(
    id: 'test-v1',
    name: 'Vario 160',
    brand: 'Honda',
    model: 'Vario 160',
    plate: 'B 1234 CD',
    currentKm: 14280,
    createdAt: DateTime(2025, 1, 1),
  );

  Widget createWidget({
    Vehicle? vehicle,
    List<ServiceRecord> records = const [],
    DateTime? initialMonth,
  }) {
    return ProviderScope(
      overrides: [
        selectedVehicleProvider.overrideWith((ref) => vehicle),
        if (vehicle != null)
          serviceRecordsStreamProvider(vehicle.id).overrideWith(
            (ref) => Stream.value(records),
          ),
      ],
      child: const MaterialApp(
        home: MonthlyReportScreen(),
      ),
    );
  }

  testWidgets('menampilkan pesan belum ada motor jika selectedVehicle null', (tester) async {
    await tester.pumpWidget(createWidget(vehicle: null));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Motor Terpilih'), findsOneWidget);
  });

  testWidgets('menampilkan ringkasan pengeluaran dan pesan bulan kosong jika tidak ada data', (tester) async {
    await tester.pumpWidget(createWidget(
      vehicle: testVehicle,
      records: [],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Laporan Bulanan'), findsOneWidget);
    expect(find.text('PENGELUARAN BULAN INI'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
    expect(find.text('Belum ada transaksi servis tercatat'), findsOneWidget);

    // Kriteria F8: Bulan tanpa data menampilkan pesan yang jelas, bukan PDF kosong
    expect(find.text('Belum Ada Catatan Servis'), findsOneWidget);
    expect(find.textContaining('Tidak ada catatan perawatan atau pengeluaran servis pada'), findsOneWidget);

    // Tombol Unduh Laporan PDF dinonaktifkan jika tidak ada data
    final downloadButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Unduh Laporan PDF'),
    );
    expect(downloadButton.onPressed, isNull);
  });

  testWidgets('menampilkan total pengeluaran dan rincian catatan servis saat ada data', (tester) async {
    final now = DateTime.now();
    final records = [
      ServiceRecord(
        id: 'rec1',
        vehicleId: testVehicle.id,
        componentType: 'engine_oil',
        date: DateTime(now.year, now.month, 10),
        km: 14000,
        brand: 'SPX2',
        price: 150000,
        location: 'Bengkel AHASS',
      ),
    ];

    await tester.pumpWidget(createWidget(
      vehicle: testVehicle,
      records: records,
    ));
    await tester.pumpAndSettle();

    // Total pengeluaran terhitung dan muncul di kartu ringkasan serta di catatan servis
    expect(find.text('Rp 150.000'), findsNWidgets(2));
    expect(find.text('1 catatan servis pada bulan ini'), findsOneWidget);

    // Daftar rincian tampil
    expect(find.text('Rincian Servis'), findsOneWidget);
    expect(find.text('Oli Mesin'), findsOneWidget);
    expect(find.text('Bengkel AHASS'), findsOneWidget);

    // Tombol Unduh Laporan PDF aktif
    final downloadButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Unduh Laporan PDF'),
    );
    expect(downloadButton.onPressed, isNotNull);
  });

  testWidgets('bisa berpindah bulan dengan tombol navigasi chevron', (tester) async {
    await tester.pumpWidget(createWidget(
      vehicle: testVehicle,
      records: [],
    ));
    await tester.pumpAndSettle();

    // Dapatkan teks bulan awal
    final prevMonthButton = find.byTooltip('Bulan Sebelumnya');
    expect(prevMonthButton, findsOneWidget);

    await tester.tap(prevMonthButton);
    await tester.pumpAndSettle();

    // Bulan mundur berhasil di-trigger tanpa error
    expect(find.byType(MonthlyReportScreen), findsOneWidget);
  });
}
