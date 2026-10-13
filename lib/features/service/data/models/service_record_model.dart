import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/service_calculator.dart';
import '../../../../core/vehicle_components.dart';

/// Model data catatan riwayat servis kendaraan
/// sesuai docs/SPEC.md bagian 4:
/// `users/{uid}/vehicles/{vehicleId}/serviceRecords/{id}`
/// field: date, km, location, price (rupiah, integer; total satu kunjungan), note, items[]
/// items[] = { kind: "component" | "part", componentType, action: "replaced" | "cleaned", name, brand }
class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.items,
    required this.date,
    required this.km,
    required this.price,
    required this.location,
    this.note,
    this.createdAt,
  });

  /// ID unik dokumen di subkoleksi serviceRecords
  final String id;

  /// ID kendaraan pemilik catatan servis ini
  final String vehicleId;

  /// Daftar item pekerjaan servis pada kunjungan ini (minimal 1)
  final List<ServiceItem> items;

  /// Tanggal servis dilakukan
  final DateTime date;

  /// Kilometer odometer saat servis dilakukan
  final int km;

  /// Total biaya servis dalam satuan rupiah integer (mis. 145000, minimal 0)
  final int price;

  /// Lokasi / Nama bengkel pengerjaan
  final String location;

  /// Catatan mekanik atau keluhan tambahan (opsional)
  final String? note;

  /// Timestamp pencatatan dibuat
  final DateTime? createdAt;

  /// Ringkasan teks item sesuai SPEC: "Oli Mesin (diganti), V-Belt (dibersihkan), Roller (diganti)"
  String get itemsSummary => ServiceCalculator.formatItemsSummary(items);

  /// Ringkasan detail dengan merek
  String get itemsDetailSummary => ServiceCalculator.formatItemsSummary(items, includeBrand: true);

  /// String harga terformat rupiah Indonesia (mis. "Rp 145.000")
  String get formattedPrice => ServiceCalculator.formatRupiah(price);

  /// String tanggal terformat Indonesia (mis. "15 Mar 2025")
  String get formattedDate => ServiceCalculator.formatDate(date);

  /// String kilometer terformat (mis. "14.280 KM")
  String get formattedKm => '${ServiceCalculator.formatKm(km)} KM';

  /// Konversi ke ServiceRecordSummary murni untuk kalkulasi
  ServiceRecordSummary toSummary() => ServiceRecordSummary(km: km, items: items);

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

    // Parsing items[] dengan fallback toleran untuk data uji lama
    List<ServiceItem> parsedItems = [];
    if (data['items'] is List) {
      final rawList = data['items'] as List;
      for (final raw in rawList) {
        if (raw is Map) {
          parsedItems.add(ServiceItem.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    // Backward compatibility untuk catatan lama (skema single componentType)
    if (parsedItems.isEmpty && data['componentType'] != null) {
      final oldComp = data['componentType'] as String? ?? ComponentType.engineOil;
      final oldBrand = data['brand'] as String?;
      parsedItems.add(
        ServiceItem(
          kind: ServiceItemKind.component,
          componentType: oldComp,
          action: ServiceItemAction.replaced,
          brand: oldBrand,
        ),
      );
    }

    return ServiceRecord(
      id: doc.id,
      vehicleId: data['vehicleId'] as String? ?? fallbackVehicleId ?? '',
      items: parsedItems,
      date: parseTimestamp(data['date']),
      km: (data['km'] as num?)?.toInt() ?? 0,
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
      'items': items.map((i) => i.toMap()).toList(),
      'date': Timestamp.fromDate(date),
      'km': km,
      'price': price,
      'location': location.trim(),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }

  ServiceRecord copyWith({
    String? id,
    String? vehicleId,
    List<ServiceItem>? items,
    DateTime? date,
    int? km,
    int? price,
    String? location,
    String? note,
    DateTime? createdAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      items: items ?? this.items,
      date: date ?? this.date,
      km: km ?? this.km,
      price: price ?? this.price,
      location: location ?? this.location,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
