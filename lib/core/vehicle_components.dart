/// Definisi konstanta dan fungsi murni terkait komponen motor
/// sesuai dengan docs/SPEC.md bagian 2.1.
library;

/// Jenis komponen motor matic standar
abstract final class ComponentType {
  static const String engineOil = 'engine_oil';
  static const String gearOil = 'gear_oil';
  static const String vBelt = 'v_belt';

  static const List<String> values = [
    engineOil,
    gearOil,
    vBelt,
  ];

  static String getLabel(String type) {
    switch (type) {
      case engineOil:
        return 'Oli Mesin';
      case gearOil:
        return 'Oli Gardan';
      case vBelt:
        return 'V-Belt';
      default:
        return type;
    }
  }
}

/// Interval default penggantian komponen (dalam kilometer)
abstract final class DefaultIntervals {
  static const int engineOil = 2000;
  static const int gearOil = 8000;
  static const int vBelt = 20000;

  static int forType(String type) {
    switch (type) {
      case ComponentType.engineOil:
        return engineOil;
      case ComponentType.gearOil:
        return gearOil;
      case ComponentType.vBelt:
        return vBelt;
      default:
        return 2000;
    }
  }
}

/// Data struktur komponen bawaan motor
class DefaultComponentData {
  const DefaultComponentData({
    required this.type,
    required this.intervalKm,
    required this.lastServiceKm,
  });

  final String type;
  final int intervalKm;
  final int lastServiceKm;

  String get label => ComponentType.getLabel(type);

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'intervalKm': intervalKm,
      'lastServiceKm': lastServiceKm,
    };
  }
}

/// Membuat tiga komponen default (oli mesin, oli gardan, V-belt)
/// dengan lastServiceKm = currentKm (dianggap baru diservis, mulai 100%)
/// sesuai aturan docs/SPEC.md bagian 2.1.
List<DefaultComponentData> createDefaultComponents(int currentKm) {
  final safeKm = currentKm < 0 ? 0 : currentKm;
  return [
    DefaultComponentData(
      type: ComponentType.engineOil,
      intervalKm: DefaultIntervals.engineOil,
      lastServiceKm: safeKm,
    ),
    DefaultComponentData(
      type: ComponentType.gearOil,
      intervalKm: DefaultIntervals.gearOil,
      lastServiceKm: safeKm,
    ),
    DefaultComponentData(
      type: ComponentType.vBelt,
      intervalKm: DefaultIntervals.vBelt,
      lastServiceKm: safeKm,
    ),
  ];
}

/// Preset motor matic populer di Indonesia untuk memudahkan pengguna memilih
class VehiclePreset {
  const VehiclePreset({
    required this.brand,
    required this.model,
  });

  final String brand;
  final String model;

  String get fullName => '$brand $model';
}

/// Daftar preset merek dan model motor matic populer
abstract final class VehiclePresets {
  static const List<String> brands = [
    'Honda',
    'Yamaha',
    'Suzuki',
    'Vespa',
  ];

  static const List<VehiclePreset> models = [
    // Honda
    VehiclePreset(brand: 'Honda', model: 'BeAT'),
    VehiclePreset(brand: 'Honda', model: 'Vario 125'),
    VehiclePreset(brand: 'Honda', model: 'Vario 160'),
    VehiclePreset(brand: 'Honda', model: 'Scoopy'),
    VehiclePreset(brand: 'Honda', model: 'PCX 160'),
    VehiclePreset(brand: 'Honda', model: 'ADV 160'),
    VehiclePreset(brand: 'Honda', model: 'Genio'),
    VehiclePreset(brand: 'Honda', model: 'Stylo 160'),
    // Yamaha
    VehiclePreset(brand: 'Yamaha', model: 'NMAX 155'),
    VehiclePreset(brand: 'Yamaha', model: 'Aerox 155'),
    VehiclePreset(brand: 'Yamaha', model: 'Mio M3'),
    VehiclePreset(brand: 'Yamaha', model: 'Fazzio'),
    VehiclePreset(brand: 'Yamaha', model: 'Grand Filano'),
    VehiclePreset(brand: 'Yamaha', model: 'Lexi LX 155'),
    VehiclePreset(brand: 'Yamaha', model: 'XMAX 250'),
    // Suzuki
    VehiclePreset(brand: 'Suzuki', model: 'Address FI'),
    VehiclePreset(brand: 'Suzuki', model: 'Nex II'),
    VehiclePreset(brand: 'Suzuki', model: 'Burgman Street 125 EX'),
    VehiclePreset(brand: 'Suzuki', model: 'Avenis 125'),
    // Vespa
    VehiclePreset(brand: 'Vespa', model: 'Sprint 150'),
    VehiclePreset(brand: 'Vespa', model: 'Primavera 150'),
    VehiclePreset(brand: 'Vespa', model: 'GTS 150'),
    VehiclePreset(brand: 'Vespa', model: 'LX 125'),
  ];
}
