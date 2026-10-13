import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/vehicle_components.dart';
import 'package:motocare/features/service/ui/service_form_screen.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_model.dart';
import 'package:motocare/features/vehicles/providers/vehicle_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testVehicle = Vehicle(
    id: 'test-vehicle-vario',
    name: 'Honda Vario 160 ABS',
    brand: 'Honda',
    model: 'Vario 160 ABS',
    plate: 'B 4291 XYZ',
    currentKm: 14280,
    createdAt: DateTime(2025, 1, 1),
  );

  Widget buildTestableScreen({String? initialComponentType}) {
    return ProviderScope(
      overrides: [
        vehiclesStreamProvider.overrideWith((ref) => Stream.value([testVehicle])),
        selectedVehicleProvider.overrideWithValue(testVehicle),
      ],
      child: MaterialApp(
        home: ServiceFormScreen(
          vehicleId: testVehicle.id,
          initialComponentType: initialComponentType,
        ),
      ),
    );
  }

  group('ServiceFormScreen Widget Tests', () {
    testWidgets('menampilkan seluruh komponen formulir sesuai SPEC F5 dan desain', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Judul dan Header
      expect(find.text('Form Catat Servis'), findsOneWidget);
      expect(find.text('MOTOR AKTIF'), findsOneWidget);
      expect(find.textContaining('Honda Vario 160 ABS'), findsWidgets);
      expect(find.text('Odo: 14.280 KM'), findsOneWidget);

      // Pilihan Komponen Utama (Matic)
      expect(find.text('KOMPONEN UTAMA (MATIC)'), findsOneWidget);
      expect(find.text('Oli Mesin'), findsOneWidget);
      expect(find.text('Oli Gardan'), findsOneWidget);
      expect(find.text('V-Belt (CVT)'), findsOneWidget);

      // Part Lain yang Diganti
      expect(find.text('PART LAIN YANG DIGANTI'), findsOneWidget);
      expect(find.text('Tambah Part Lain'), findsOneWidget);

      // Label Kolom Input
      expect(find.text('ODOMETER SAAT SERVIS (KM)'), findsOneWidget);
      expect(find.text('TANGGAL SERVIS'), findsOneWidget);
      expect(find.text('NAMA BENGKEL / TEMPAT PENGERJAAN'), findsOneWidget);
      expect(find.text('TOTAL BIAYA SERVIS & SUKU CADANG (SATU KUNJUNGAN)'), findsOneWidget);
      expect(find.text('CATATAN MEKANIK / KELUHAN (OPSIONAL)'), findsOneWidget);

      // Tombol Simpan
      expect(find.text('Simpan Catatan Servis'), findsOneWidget);
    });

    testWidgets('tombol Gunakan KM Terkini mengisi nilai KM odometer', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Cari input KM dan kosongkan
      final kmFieldFinder = find.byType(TextField).at(1); // field 0 adalah merek oli mesin karena tercentang awal
      await tester.enterText(kmFieldFinder, '');
      await tester.pumpAndSettle();

      // Tap tombol "Gunakan KM Terkini"
      final useCurrentKmBtn = find.textContaining('Gunakan KM Terkini');
      expect(useCurrentKmBtn, findsOneWidget);
      await tester.tap(useCurrentKmBtn);
      await tester.pumpAndSettle();

      // Memastikan nilai KM kembali terisi 14280
      expect(find.text('14280'), findsOneWidget);
    });

    testWidgets('initialComponentType otomatis memilih komponen yang sesuai', (tester) async {
      await tester.pumpWidget(
        buildTestableScreen(initialComponentType: ComponentType.vBelt),
      );
      await tester.pumpAndSettle();

      // V-Belt terpilih sehingga opsi Diganti dan Dibersihkan muncul
      expect(find.text('Diganti'), findsOneWidget);
      expect(find.text('Dibersihkan'), findsOneWidget);
    });

    testWidgets('bisa menambah dan menghapus baris part lain', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final addPartBtn = find.text('Tambah Part Lain');
      await tester.ensureVisible(addPartBtn);
      await tester.tap(addPartBtn);
      await tester.pumpAndSettle();

      final deleteBtn = find.byTooltip('Hapus part');
      expect(deleteBtn, findsOneWidget);
      expect(find.text('Nama part (mis. Roller, Busi)'), findsOneWidget);

      // Hapus baris part
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hapus part'), findsNothing);
    });

    testWidgets('menolak submit jika input wajib kosong dengan pesan error yang jelas', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Uncheck Oli Mesin agar 0 item terpilih
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Kosongkan KM field
      final kmField = find.widgetWithText(TextField, '14280');
      if (kmField.evaluate().isNotEmpty) {
        await tester.enterText(kmField, '');
      }

      // Tekan tombol Simpan
      final submitBtn = find.text('Simpan Catatan Servis');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Validasi pesan error tampil
      expect(find.text('Kilometer servis wajib diisi'), findsOneWidget);
      expect(find.text('Nama bengkel atau tempat servis wajib diisi'), findsOneWidget);
      expect(find.text('Total biaya wajib diisi (ketik 0 jika gratis)'), findsOneWidget);
      expect(find.text('Pilih minimal satu komponen atau tambahkan part lain'), findsOneWidget);
    });

    testWidgets('tidak terjadi overflow pada layar ponsel standar Android (392.7 dan 360 dp)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ODOMETER SAAT SERVIS (KM)'), findsOneWidget);
      expect(find.textContaining('Gunakan KM Terkini'), findsOneWidget);
    });
  });
}
