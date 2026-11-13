import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/vehicle_components.dart';

/// Model komponen motor di subkoleksi components/{type}
/// sesuai docs/SPEC.md bagian 4:
/// `type, intervalKm, lastServiceKm, baselineKm (KM saat motor dibuat)`
class VehicleComponent {
  const VehicleComponent({
    required this.type,
    required this.intervalKm,
    required this.lastServiceKm,
    required this.baselineKm,
    this.lastRedNotifiedKm,
    this.hasPendingWrites = false,
  });

  final String type;
  final int intervalKm;
  final int lastServiceKm;
  final int baselineKm;

  /// True bila dokumen masih menunggu dikirim ke server (disimpan di HP saja).
  final bool hasPendingWrites;

  /// KM saat notifikasi "sudah masuk zona merah" terakhir ditampilkan.
  /// Dipakai agar notifikasi itu tidak muncul berulang tiap aplikasi dibuka.
  final int? lastRedNotifiedKm;

  String get label => ComponentType.getLabel(type);

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'intervalKm': intervalKm,
      'lastServiceKm': lastServiceKm,
      'baselineKm': baselineKm,
      if (lastRedNotifiedKm != null) 'lastRedNotifiedKm': lastRedNotifiedKm,
    };
  }

  factory VehicleComponent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final type = (data['type'] as String?) ?? doc.id;
    final lastServiceKm = (data['lastServiceKm'] as num?)?.toInt() ?? 0;
    // Fallback baselineKm ke lastServiceKm jika belum tersimpan (data lama)
    final baselineKm = (data['baselineKm'] as num?)?.toInt() ?? lastServiceKm;

    return VehicleComponent(
      type: type,
      intervalKm: (data['intervalKm'] as num?)?.toInt() ??
          DefaultIntervals.forType(type),
      lastServiceKm: lastServiceKm,
      baselineKm: baselineKm,
      lastRedNotifiedKm: (data['lastRedNotifiedKm'] as num?)?.toInt(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }

  VehicleComponent copyWith({
    String? type,
    int? intervalKm,
    int? lastServiceKm,
    int? baselineKm,
    int? lastRedNotifiedKm,
    bool? hasPendingWrites,
  }) {
    return VehicleComponent(
      type: type ?? this.type,
      intervalKm: intervalKm ?? this.intervalKm,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
      baselineKm: baselineKm ?? this.baselineKm,
      lastRedNotifiedKm: lastRedNotifiedKm ?? this.lastRedNotifiedKm,
      hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
    );
  }
}
