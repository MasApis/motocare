import 'package:cloud_firestore/cloud_firestore.dart';

/// Model kendaraan sesuai docs/SPEC.md bagian 4
class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    this.plate,
    required this.currentKm,
    required this.createdAt,
    this.hasPendingWrites = false,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final String? plate;
  final int currentKm;
  final DateTime createdAt;

  /// True bila dokumen masih menunggu dikirim ke server (disimpan di HP saja).
  final bool hasPendingWrites;

  /// Nama tampilan motor: jika name kosong, gunakan kombinasi brand + model
  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    final combined = '$brand $model'.trim();
    return combined.isNotEmpty ? combined : 'Motor Tanpa Nama';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'model': model,
      if (plate != null && plate!.trim().isNotEmpty) 'plate': plate!.trim(),
      'currentKm': currentKm,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Vehicle.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return Vehicle(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      brand: (data['brand'] as String?) ?? '',
      model: (data['model'] as String?) ?? '',
      plate: data['plate'] as String?,
      currentKm: (data['currentKm'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }

  Vehicle copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    String? plate,
    int? currentKm,
    DateTime? createdAt,
    bool? hasPendingWrites,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plate: plate ?? this.plate,
      currentKm: currentKm ?? this.currentKm,
      createdAt: createdAt ?? this.createdAt,
      hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
    );
  }
}
