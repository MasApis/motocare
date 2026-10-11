import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/vehicle_components.dart';
import 'package:motocare/features/dashboard/ui/widgets/component_health_card.dart';
import 'package:motocare/shared/widgets/app_progress_bar.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  group('ComponentHealthCard Widget Tests', () {
    testWidgets('menampilkan komponen Oli Mesin berstatus Aman (> 30%) dengan benar', (tester) async {
      // Oli mesin: interval 2000, lastServiceKm 10000, currentKm 10500 (terpakai 500 km = 25%, sisa 1500 km = 75%)
      await tester.pumpWidget(
        buildTestableWidget(
          const ComponentHealthCard(
            componentType: ComponentType.engineOil,
            intervalKm: 2000,
            lastServiceKm: 10000,
            currentKm: 10500,
          ),
        ),
      );

      // Verifikasi judul dan interval
      expect(find.text('Oli Mesin'), findsOneWidget);
      expect(find.text('Interval tiap 2.000 km'), findsOneWidget);

      // Verifikasi status badge teks (bukan hanya warna)
      expect(find.text('Aman'), findsOneWidget);

      // Verifikasi persen terpakai dan sisa KM
      expect(find.text('25% terpakai'), findsOneWidget);
      expect(find.text('Sisa 1.500 km'), findsOneWidget);

      // Verifikasi ada progress bar
      expect(find.byType(AppProgressBar), findsOneWidget);
    });

    testWidgets('menampilkan Oli Gardan berstatus Peringatan (10% - 30%) dengan benar', (tester) async {
      // Oli gardan: interval 8000, lastServiceKm 10000, currentKm 16400 (terpakai 6400 km = 80%, sisa 1600 km = 20%)
      await tester.pumpWidget(
        buildTestableWidget(
          const ComponentHealthCard(
            componentType: ComponentType.gearOil,
            intervalKm: 8000,
            lastServiceKm: 10000,
            currentKm: 16400,
          ),
        ),
      );

      expect(find.text('Oli Gardan'), findsOneWidget);
      expect(find.text('Interval tiap 8.000 km'), findsOneWidget);

      // Teks status Peringatan
      expect(find.text('Peringatan'), findsOneWidget);
      expect(find.text('80% terpakai'), findsOneWidget);
      expect(find.text('Sisa 1.600 km'), findsOneWidget);
    });

    testWidgets('menampilkan V-Belt berstatus Batas habis (< 10%) dengan benar', (tester) async {
      // V-belt: interval 20000, lastServiceKm 10000, currentKm 29000 (terpakai 19000 km = 95%, sisa 1000 km = 5%)
      await tester.pumpWidget(
        buildTestableWidget(
          const ComponentHealthCard(
            componentType: ComponentType.vBelt,
            intervalKm: 20000,
            lastServiceKm: 10000,
            currentKm: 29000,
          ),
        ),
      );

      expect(find.text('V-Belt'), findsOneWidget);
      expect(find.text('Interval tiap 20.000 km'), findsOneWidget);

      // Teks status Batas habis
      expect(find.text('Batas habis'), findsOneWidget);
      expect(find.text('95% terpakai'), findsOneWidget);
      expect(find.text('Sisa 1.000 km'), findsOneWidget);
    });

    testWidgets('menampilkan kondisi KM melebihi interval dengan teks Lewat X km', (tester) async {
      // Interval 2000, lastServiceKm 10000, currentKm 12500 (terpakai 2500 km, lewat 500 km)
      await tester.pumpWidget(
        buildTestableWidget(
          const ComponentHealthCard(
            componentType: ComponentType.engineOil,
            intervalKm: 2000,
            lastServiceKm: 10000,
            currentKm: 12500,
          ),
        ),
      );

      expect(find.text('Batas habis'), findsOneWidget);
      expect(find.text('100% terpakai'), findsOneWidget);
      expect(find.text('Lewat 500 km'), findsOneWidget);
    });
  });
}
