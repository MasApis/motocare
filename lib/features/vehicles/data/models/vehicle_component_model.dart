import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/vehicle_components.dart';

/// Model komponen motor di subkoleksi components/{type}
/// sesuai docs/SPEC.md bagian 4
class VehicleComponent {
  const VehicleComponent({
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

  factory VehicleComponent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final type = (data['type'] as String?) ?? doc.id;
    return VehicleComponent(
      type: type,
      intervalKm: (data['intervalKm'] as num?)?.toInt() ??
          DefaultIntervals.forType(type),
      lastServiceKm: (data['lastServiceKm'] as num?)?.toInt() ?? 0,
    );
  }

  VehicleComponent copyWith({
    String? type,
    int? intervalKm,
    int? lastServiceKm,
  }) {
    return VehicleComponent(
      type: type ?? this.type,
      intervalKm: intervalKm ?? this.intervalKm,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
    );
  }
}
