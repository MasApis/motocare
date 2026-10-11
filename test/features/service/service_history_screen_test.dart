import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/vehicle_components.dart';
import 'package:motocare/features/service/data/models/service_record_model.dart';
import 'package:motocare/features/service/providers/service_providers.dart';
import 'package:motocare/features/service/ui/service_history_screen.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_model.dart';
import 'package:motocare/features/vehicles/providers/vehicle_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testVehicle1 = Vehicle(
    id: 'vehicle-1',
    name: 'Honda Vario 160 ABS',
    brand: 'Honda',
    model: 'Vario 160',
    plate: 'B 4291 XYZ',
    currentKm: 14280,
    createdAt: DateTime(2025, 1, 1),
  );

  final testRecords = [
    ServiceRecord(
      id: 'rec-1',
      vehicleId: 'vehicle-1',
      componentType: ComponentType.engineOil,
      date: DateTime(2025, 3, 15),
      km: 14000,
      brand: 'SPX2 (0.8L)',
      price: 145000,
      location: 'AHASS Bintang Motor Fatmawati',
      note: 'Ganti oli berkala rutin',
      createdAt: DateTime(2025, 3, 15),
    ),
    ServiceRecord(
      id: 'rec-2',
      vehicleId: 'vehicle-1',
      componentType: ComponentType.gearOil,
      date: DateTime(2025, 1, 10),
      km: 12000,
      brand: 'Ahm Oil Gear',
      price: 45000,
      location: 'Bengkel Mandiri',
      createdAt: DateTime(2025, 1, 10),
    ),
  ];

  Widget buildTestableHistoryScreen({List<ServiceRecord>? records}) {
    return ProviderScope(
      overrides: [
        vehiclesStreamProvider.overrideWith((ref) => Stream.value([testVehicle1])),
        allServiceRecordsStreamProvider.overrideWith(
          (ref) => Stream.value(records ?? testRecords),
        ),
      ],
      child: const MaterialApp(
        home: ServiceHistoryScreen(),
      ),
    );
  }

  group('ServiceHistoryScreen Widget Tests', () {
    testWidgets('menampilkan linimasa servis lengkap, format rupiah, dan tanggal Indonesia', (tester) async {
      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      // Judul Layar
      expect(find.text('Riwayat Servis'), findsOneWidget);
      expect(find.text('Semua Motor'), findsOneWidget);

      // Verifikasi Catatan Servis 1
      expect(find.text('Rp 145.000'), findsOneWidget);
      expect(find.textContaining('Oli Mesin • SPX2'), findsOneWidget);
      expect(find.text('AHASS Bintang Motor Fatmawati'), findsOneWidget);
      expect(find.text('Ganti oli berkala rutin'), findsOneWidget);
      expect(find.text('14.000 KM'), findsOneWidget);

      // Verifikasi Catatan Servis 2
      expect(find.text('Rp 45.000'), findsOneWidget);
      expect(find.textContaining('Oli Gardan • Ahm Oil Gear'), findsOneWidget);
      expect(find.text('Bengkel Mandiri'), findsOneWidget);
      expect(find.text('12.000 KM'), findsOneWidget);
    });

    testWidgets('menekan tombol Hapus memunculkan AlertDialog konfirmasi', (tester) async {
      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      // Cari tombol Hapus pada kartu pertama
      final deleteButtons = find.text('Hapus');
      expect(deleteButtons, findsNWidgets(2));

      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Verifikasi Dialog Konfirmasi muncul dengan pesan ramah
      expect(find.text('Hapus Catatan Servis?'), findsOneWidget);
      expect(
        find.textContaining('Kartu komponen akan kembali menghitung sisa masa pakai dari servis sebelumnya'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);

      // Tekan tombol Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog tertutup
      expect(find.text('Hapus Catatan Servis?'), findsNothing);
    });

    testWidgets('menampilkan empty state jika belum ada catatan servis', (tester) async {
      await tester.pumpWidget(buildTestableHistoryScreen(records: []));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Riwayat Servis'), findsOneWidget);
      expect(find.text('Catat Servis Baru'), findsOneWidget);
    });
  });
}
