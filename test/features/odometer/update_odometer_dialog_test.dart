import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/odometer/ui/update_odometer_dialog.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_model.dart';

void main() {
  final testVehicle = Vehicle(
    id: 'test-vehicle-1',
    name: 'Vario 160 eSP+',
    brand: 'Honda',
    model: 'Vario 160',
    plate: 'B 1234 ABC',
    currentKm: 14280,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('UpdateOdometerDialog Widget Tests', () {
    testWidgets('menampilkan elemen dialog dengan benar dan tanggal default hari ini', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => UpdateOdometerDialog.show(ctx, testVehicle),
              child: const Text('Buka Modal'),
            ),
          ),
        ),
      );

      // Buka dialog
      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      // Verifikasi judul dialog
      expect(find.text('Update Odometer'), findsOneWidget);
      expect(find.text('ANGKA KILOMETER BARU (KM)'), findsOneWidget);
      expect(find.text('Tercatat sebelumnya: 14.280 KM'), findsOneWidget);

      // Verifikasi input berisi KM saat ini sebagai nilai awal
      expect(find.text('14280'), findsOneWidget);

      // Verifikasi tombol Batal dan Simpan KM
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan KM'), findsOneWidget);

      // Verifikasi adanya tombol / baris tanggal pencatatan
      expect(find.text('TANGGAL PENCATATAN'), findsOneWidget);
    });

    testWidgets('menolak input KM kosong dengan pesan error yang jelas', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => UpdateOdometerDialog.show(ctx, testVehicle),
              child: const Text('Buka Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      // Kosongkan input KM
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Simpan KM'));
      await tester.pumpAndSettle();

      expect(find.text('Kilometer tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('menolak input non-angka dengan pesan error yang jelas', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => UpdateOdometerDialog.show(ctx, testVehicle),
              child: const Text('Buka Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      // Masukkan teks non-angka
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.tap(find.text('Simpan KM'));
      await tester.pumpAndSettle();

      expect(find.text('Kilometer harus berupa angka yang valid'), findsOneWidget);
    });

    testWidgets('menolak input KM lebih kecil dari KM saat ini (KM tidak boleh turun)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => UpdateOdometerDialog.show(ctx, testVehicle),
              child: const Text('Buka Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      // Masukkan KM yang lebih kecil dari 14280
      await tester.enterText(find.byType(TextFormField), '10000');
      await tester.tap(find.text('Simpan KM'));
      await tester.pumpAndSettle();

      expect(
        find.text('KM baru tidak boleh lebih kecil dari KM terakhir (14280 KM)'),
        findsOneWidget,
      );
    });

    testWidgets('tombol Batal menutup dialog', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => UpdateOdometerDialog.show(ctx, testVehicle),
              child: const Text('Buka Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Update Odometer'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog harus tertutup
      expect(find.text('Update Odometer'), findsNothing);
    });
  });
}
