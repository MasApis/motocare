import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/dashboard/ui/widgets/vehicle_hero_card.dart';
import 'package:motocare/features/odometer/data/models/odometer_log_model.dart';
import 'package:motocare/features/odometer/providers/odometer_providers.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_model.dart';

void main() {
  final testVehicle = Vehicle(
    id: 'vehicle-1',
    name: 'Honda Vario 160 eSP+',
    brand: 'Honda',
    model: 'Vario 160',
    plate: 'B 4821 KLS',
    currentKm: 14280,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget buildTestableWidget({
    required Widget child,
    List<OdometerLog>? logs,
  }) {
    return ProviderScope(
      overrides: [
        odometerLogsStreamProvider(testVehicle.id).overrideWith(
          (ref) => Stream.value(logs ?? []),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  group('VehicleHeroCard Widget Tests', () {
    testWidgets('menampilkan info motor, odometer, dan default rata-rata "± 20 km/hari" saat data kurang', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: VehicleHeroCard(
            vehicle: testVehicle,
            itemNumber: 1,
            totalItems: 2,
          ),
          logs: [],
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi nama dan plat
      expect(find.text('Honda Vario 160 eSP+'), findsOneWidget);
      expect(find.text('Honda Vario 160 • B 4821 KLS'), findsOneWidget);
      expect(find.text('MOTOR 1 DARI 2'), findsOneWidget);

      // Verifikasi Odometer tercatat
      expect(find.text('ODOMETER TERCATAT'), findsOneWidget);
      expect(find.text('14.280'), findsOneWidget);
      expect(find.text('KM'), findsOneWidget);

      // Verifikasi rata-rata fallback 20 km/hari
      expect(find.text('Rata-rata '), findsOneWidget);
      expect(find.text('± 20 km/hari'), findsOneWidget);

      // Verifikasi tombol Update KM Hari Ini
      expect(find.text('Update KM Hari Ini'), findsOneWidget);
    });

    testWidgets('menampilkan rata-rata terhitung saat data normal tersedia', (tester) async {
      final now = DateTime.now();
      final logs = [
        OdometerLog(
          id: 'log-2',
          km: 14380, // +100 km dalam 4 hari -> 25 km/hari
          date: now,
        ),
        OdometerLog(
          id: 'log-1',
          km: 14280,
          date: now.subtract(const Duration(days: 4)),
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: VehicleHeroCard(
            vehicle: testVehicle.copyWith(currentKm: 14380),
            itemNumber: 1,
            totalItems: 1,
          ),
          logs: logs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('14.380'), findsOneWidget);
      expect(find.text('± 25 km/hari'), findsOneWidget);
    });
  });
}
