import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/service_calculator.dart';
import '../../../../core/vehicle_components.dart';

/// Model data catatan riwayat servis kendaraan
/// sesuai docs/SPEC.md bagian 4:
/// `users/{uid}/vehicles/{vehicleId}/serviceRecords/{id}`
/// field: componentType, date, km, brand, price (rupiah, integer), location, note
class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.componentType,
    required this.date,
    required this.km,
    required this.brand,
    required this.price,
    required this.location,
    this.note,
    this.createdAt,
  });

  /// ID unik dokumen di subkoleksi serviceRecords
  final String id;

  /// ID kendaraan pemilik catatan servis ini
  final String vehicleId;

  /// Tipe komponen: engine_oil, gear_oil, atau v_belt
  final String componentType;

  /// Tanggal servis dilakukan
  final DateTime date;

  /// Kilometer odometer saat servis dilakukan
  final int km;

  /// Merek suku cadang / oli (mis. SPX2, Shell Advance, dsb)
  final String brand;

  /// Total biaya servis dalam satuan rupiah integer (mis. 145000)
  final int price;

  /// Lokasi / Nama bengkel pengerjaan
  final String location;

  /// Catatan mekanik atau keluhan tambahan (opsional)
  final String? note;

  /// Timestamp pencatatan dibuat
  final DateTime? createdAt;

  /// Label ramah komponen (mis. "Oli Mesin")
  String get componentLabel => ComponentType.getLabel(componentType);

  /// String harga terformat rupiah Indonesia (mis. "Rp 145.000")
  String get formattedPrice => ServiceCalculator.formatRupiah(price);

  /// String tanggal terformat Indonesia (mis. "15 Mar 2025")
  String get formattedDate => ServiceCalculator.formatDate(date);

  /// String kilometer terformat (mis. "14.280 KM")
  String get formattedKm => '${ServiceCalculator.formatKm(km)} KM';

  /// Membuat instance ServiceRecord dari Firestore DocumentSnapshot
  factory ServiceRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? fallbackVehicleId,
  }) {
    final data = doc.data() ?? {};

    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ServiceRecord(
      id: doc.id,
      vehicleId: data['vehicleId'] as String? ?? fallbackVehicleId ?? '',
      componentType: data['componentType'] as String? ?? ComponentType.engineOil,
      date: parseTimestamp(data['date']),
      km: (data['km'] as num?)?.toInt() ?? 0,
      brand: (data['brand'] as String?)?.trim() ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      location: (data['location'] as String?)?.trim() ?? '',
      note: (data['note'] as String?)?.trim().isNotEmpty == true
          ? (data['note'] as String).trim()
          : null,
      createdAt: data['createdAt'] != null ? parseTimestamp(data['createdAt']) : null,
    );
  }

  /// Mengonversi instance ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'componentType': componentType,
      'date': Timestamp.fromDate(date),
      'km': km,
      'brand': brand.trim(),
      'price': price,
      'location': location.trim(),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }

  ServiceRecord copyWith({
    String? id,
    String? vehicleId,
    String? componentType,
    DateTime? date,
    int? km,
    String? brand,
    int? price,
    String? location,
    String? note,
    DateTime? createdAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      componentType: componentType ?? this.componentType,
      date: date ?? this.date,
      km: km ?? this.km,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      location: location ?? this.location,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
