import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/vehicle_components.dart';

void main() {
  group('createDefaultComponents', () {
    test('membuat tepat tiga komponen dengan tipe yang benar', () {
      final components = createDefaultComponents(5000);

      expect(components.length, 3);
      expect(components[0].type, ComponentType.engineOil);
      expect(components[1].type, ComponentType.gearOil);
      expect(components[2].type, ComponentType.vBelt);
    });

    test('menggunakan interval default sesuai SPEC bagian 2.1', () {
      final components = createDefaultComponents(10000);

      final engineOil = components.firstWhere((c) => c.type == ComponentType.engineOil);
      final gearOil = components.firstWhere((c) => c.type == ComponentType.gearOil);
      final vBelt = components.firstWhere((c) => c.type == ComponentType.vBelt);

      expect(engineOil.intervalKm, 2000);
      expect(gearOil.intervalKm, 8000);
      expect(vBelt.intervalKm, 20000);
    });

    test('lastServiceKm sama dengan currentKm saat motor dibuat (mulai 100%)', () {
      const currentKm = 14280;
      final components = createDefaultComponents(currentKm);

      for (final component in components) {
        expect(component.lastServiceKm, currentKm);
      }
    });

    test('menangani currentKm negatif dengan mengubah menjadi 0', () {
      final components = createDefaultComponents(-50);

      for (final component in components) {
        expect(component.lastServiceKm, 0);
      }
    });
  });

  group('ComponentType & Labels', () {
    test('memberikan label bahasa Indonesia yang ramah', () {
      expect(ComponentType.getLabel(ComponentType.engineOil), 'Oli Mesin');
      expect(ComponentType.getLabel(ComponentType.gearOil), 'Oli Gardan');
      expect(ComponentType.getLabel(ComponentType.vBelt), 'V-Belt');
      expect(ComponentType.getLabel('unknown'), 'unknown');
    });
  });

  group('VehiclePresets', () {
    test('memiliki daftar preset matic populer', () {
      expect(VehiclePresets.brands, containsAll(['Honda', 'Yamaha', 'Suzuki', 'Vespa']));
      expect(VehiclePresets.models, isNotEmpty);
      expect(VehiclePresets.models.any((m) => m.brand == 'Honda' && m.model == 'Vario 160'), isTrue);
    });
  });
}
