import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/vehicle_components.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_component_model.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_model.dart';

void main() {
  group('Vehicle Model', () {
    test('displayName menggunakan name jika name terisi', () {
      final v = Vehicle(
        id: 'v1',
        name: 'Si Hitam Gesit',
        brand: 'Honda',
        model: 'Vario 160',
        currentKm: 14280,
        createdAt: DateTime.now(),
      );
      expect(v.displayName, 'Si Hitam Gesit');
    });

    test(r'displayName fallback ke "$brand $model" jika name kosong', () {
      final v = Vehicle(
        id: 'v2',
        name: '',
        brand: 'Yamaha',
        model: 'NMAX 155',
        currentKm: 5000,
        createdAt: DateTime.now(),
      );
      expect(v.displayName, 'Yamaha NMAX 155');
    });

    test('toMap menghasilkan map sesuai spesifikasi Firestore SPEC 4', () {
      final now = DateTime.now();
      final v = Vehicle(
        id: 'v1',
        name: 'Vario Keren',
        brand: 'Honda',
        model: 'Vario 160',
        plate: 'B 1234 KLS',
        currentKm: 12000,
        createdAt: now,
      );

      final map = v.toMap();
      expect(map['name'], 'Vario Keren');
      expect(map['brand'], 'Honda');
      expect(map['model'], 'Vario 160');
      expect(map['plate'], 'B 1234 KLS');
      expect(map['currentKm'], 12000);
      expect(map['createdAt'], isA<Timestamp>());
    });
  });

  group('VehicleComponent Model', () {
    test('memberikan label ramah dan interval default', () {
      const comp = VehicleComponent(
        type: ComponentType.engineOil,
        intervalKm: 2000,
        lastServiceKm: 10000,
      );

      expect(comp.label, 'Oli Mesin');
      expect(comp.intervalKm, 2000);
      expect(comp.lastServiceKm, 10000);
    });

    test('toMap menghasilkan struktur subkoleksi components', () {
      const comp = VehicleComponent(
        type: ComponentType.vBelt,
        intervalKm: 20000,
        lastServiceKm: 5000,
      );

      final map = comp.toMap();
      expect(map['type'], ComponentType.vBelt);
      expect(map['intervalKm'], 20000);
      expect(map['lastServiceKm'], 5000);
    });
  });
}
