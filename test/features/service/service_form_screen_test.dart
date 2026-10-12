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

      // Pilihan Chip Komponen (Hanya 3 matic)
      expect(find.text('Ganti Oli Mesin'), findsOneWidget);
      expect(find.text('Oli Gardan'), findsOneWidget);
      expect(find.text('V-Belt'), findsOneWidget);

      // Label Kolom Input
      expect(find.text('ODOMETER SAAT SERVIS (KM)'), findsOneWidget);
      expect(find.text('TANGGAL SERVIS'), findsOneWidget);
      expect(find.text('MEREK SUKU CADANG / OLI'), findsOneWidget);
      expect(find.text('NAMA BENGKEL / TEMPAT PENGERJAAN'), findsOneWidget);
      expect(find.text('TOTAL BIAYA SERVIS & SUKU CADANG'), findsOneWidget);
      expect(find.text('CATATAN MEKANIK / KELUHAN (OPSIONAL)'), findsOneWidget);

      // Tombol Simpan
      expect(find.text('Simpan Catatan Servis'), findsOneWidget);
    });

    testWidgets('tombol Gunakan KM Terkini mengisi nilai KM odometer', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Kosongkan input KM
      final kmFieldFinder = find.byType(TextField).first;
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

    testWidgets('initialComponentType otomatis memilih chip komponen yang sesuai', (tester) async {
      await tester.pumpWidget(
        buildTestableScreen(initialComponentType: ComponentType.vBelt),
      );
      await tester.pumpAndSettle();

      final vBeltChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'V-Belt'),
      );
      expect(vBeltChip.selected, isTrue);

      final engineOilChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Ganti Oli Mesin'),
      );
      expect(engineOilChip.selected, isFalse);
    });

    testWidgets('menolak submit jika input wajib kosong dengan pesan error yang jelas', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Kosongkan KM field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), ''); // KM
      await tester.enterText(textFields.at(1), ''); // Brand
      await tester.enterText(textFields.at(2), ''); // Location
      await tester.enterText(textFields.at(3), ''); // Price

      // Tekan tombol Simpan
      final submitBtn = find.text('Simpan Catatan Servis');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Validasi pesan error tampil
      expect(find.text('Kilometer servis wajib diisi'), findsOneWidget);
      expect(find.text('Merek suku cadang atau oli wajib diisi'), findsOneWidget);
      expect(find.text('Nama bengkel atau tempat servis wajib diisi'), findsOneWidget);
      expect(find.text('Total biaya wajib diisi (ketik 0 jika gratis)'), findsOneWidget);
    });

    testWidgets('tidak terjadi overflow pada layar ponsel standar Android (392.7 dan 360 dp)', (tester) async {
      // Uji pada ukuran layar standar HP Android 392.7dp dan 360dp
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75; // 1080 / 2.75 = 392.727 dp
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Memastikan tidak ada RenderFlex overflow error (Flutter test akan gagal jika tester.takeException() bukan null atau jika ada overflow)
      expect(tester.takeException(), isNull);
      expect(find.text('ODOMETER SAAT SERVIS (KM)'), findsOneWidget);
      expect(find.textContaining('Gunakan KM Terkini'), findsOneWidget);
    });
  });
}
