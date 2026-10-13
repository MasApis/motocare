import 'package:intl/intl.dart';
import 'vehicle_components.dart';

/// Jenis item pada satu kunjungan servis
enum ServiceItemKind {
  component,
  part,
}

/// Aksi penanganan item saat servis
enum ServiceItemAction {
  replaced,
  cleaned,
}

/// Representasi item servis murni (tanpa dependensi Firestore)
class ServiceItem {
  const ServiceItem({
    required this.kind,
    this.componentType,
    required this.action,
    this.name,
    this.brand,
  });

  final ServiceItemKind kind;
  final String? componentType;
  final ServiceItemAction action;
  final String? name;
  final String? brand;

  /// Label nama item yang ramah pengguna
  String get displayName {
    if (kind == ServiceItemKind.component) {
      return ComponentType.getLabel(componentType ?? '');
    }
    return name?.trim().isNotEmpty == true ? name!.trim() : 'Part Lain';
  }

  /// Label aksi dalam bahasa Indonesia ("diganti" / "dibersihkan")
  String get actionLabel {
    switch (action) {
      case ServiceItemAction.replaced:
        return 'diganti';
      case ServiceItemAction.cleaned:
        return 'dibersihkan';
    }
  }

  /// Ringkasan terformat: "Oli Mesin (diganti)" atau "Roller (diganti, KTC)"
  String get formattedSummary {
    final b = (brand != null && brand!.trim().isNotEmpty) ? ', ${brand!.trim()}' : '';
    return '$displayName ($actionLabel$b)';
  }

  /// Ringkasan singkat tanpa merek: "Oli Mesin (diganti)"
  String get shortSummary => '$displayName ($actionLabel)';

  Map<String, dynamic> toMap() {
    return {
      'kind': kind.name,
      if (componentType != null) 'componentType': componentType,
      'action': action.name,
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (brand != null && brand!.trim().isNotEmpty) 'brand': brand!.trim(),
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    final kindStr = map['kind'] as String? ?? 'component';
    final kind = kindStr == 'part' ? ServiceItemKind.part : ServiceItemKind.component;
    final actionStr = map['action'] as String? ?? 'replaced';
    final action = actionStr == 'cleaned' ? ServiceItemAction.cleaned : ServiceItemAction.replaced;

    return ServiceItem(
      kind: kind,
      componentType: map['componentType'] as String?,
      action: action,
      name: map['name'] as String?,
      brand: map['brand'] as String?,
    );
  }

  ServiceItem copyWith({
    ServiceItemKind? kind,
    String? componentType,
    ServiceItemAction? action,
    String? name,
    String? brand,
  }) {
    return ServiceItem(
      kind: kind ?? this.kind,
      componentType: componentType ?? this.componentType,
      action: action ?? this.action,
      name: name ?? this.name,
      brand: brand ?? this.brand,
    );
  }
}

/// Ringkasan catatan servis murni untuk perhitungan
class ServiceRecordSummary {
  const ServiceRecordSummary({
    required this.km,
    required this.items,
  });

  final int km;
  final List<ServiceItem> items;
}

/// Fungsi-fungsi murni untuk perhitungan servis dan riwayat
/// sesuai dengan docs/SPEC.md bagian 5 (F5) dan Bagian 2.1.
abstract final class ServiceCalculator {
  /// Menentukan lastServiceKm baru setelah servis dilakukan pada [serviceKm].
  /// Kartu komponen akan menghitung pemakaian dari KM ini,
  /// sehingga jika servis dilakukan pada KM saat ini, kartu kembali 100%.
  static int calculateNewLastServiceKm({
    required int serviceKm,
  }) {
    return serviceKm < 0 ? 0 : serviceKm;
  }

  /// Menentukan komponen apa saja yang perlu di-reset kartunya (lastServiceKm = serviceKm).
  /// Sesuai aturan SPEC bagian 2.1:
  /// - Hanya komponen bertipe component yang berstatus "replaced" (diganti) yang mereset kartunya.
  /// - Komponen yang "cleaned" (dibersihkan) TIDAK mereset kartu.
  /// - Part lain (kind == part) TIDAK memengaruhi kartu manapun.
  static Set<String> getComponentsToReset(List<ServiceItem> items) {
    final resetTypes = <String>{};
    for (final item in items) {
      if (item.kind == ServiceItemKind.component &&
          item.action == ServiceItemAction.replaced &&
          item.componentType != null &&
          item.componentType!.isNotEmpty) {
        resetTypes.add(item.componentType!);
      }
    }
    return resetTypes;
  }

  /// Menghitung lastServiceKm komponen setelah sebuah catatan servis dihapus.
  ///
  /// Aturan SPEC 2.1 & F5:
  /// "Saat catatan dihapus, lastServiceKm tiap komponen dihitung ulang: KM dari catatan
  /// 'diganti' untuk komponen itu dengan KM tertinggi yang tersisa; jika tidak ada, kembali ke baselineKm."
  static int calculateComponentLastServiceKmAfterDelete({
    required String componentType,
    required int baselineKm,
    required List<ServiceRecordSummary> remainingRecords,
  }) {
    int? maxReplacedKm;

    for (final record in remainingRecords) {
      final isReplaced = record.items.any((item) =>
          item.kind == ServiceItemKind.component &&
          item.componentType == componentType &&
          item.action == ServiceItemAction.replaced);

      if (isReplaced) {
        if (maxReplacedKm == null || record.km > maxReplacedKm) {
          maxReplacedKm = record.km;
        }
      }
    }

    if (maxReplacedKm != null) {
      return maxReplacedKm < 0 ? 0 : maxReplacedKm;
    }
    return baselineKm < 0 ? 0 : baselineKm;
  }

  /// Kompatibilitas mundur untuk daftar KM mentah
  static int calculateLastServiceKmAfterDelete({
    required int initialKm,
    required List<int> remainingServiceKms,
  }) {
    if (remainingServiceKms.isEmpty) {
      return initialKm < 0 ? 0 : initialKm;
    }

    int maxKm = remainingServiceKms.first;
    for (final km in remainingServiceKms) {
      if (km > maxKm) {
        maxKm = km;
      }
    }
    return maxKm < 0 ? 0 : maxKm;
  }

  /// Format string ringkasan daftar item servis untuk riwayat dan laporan PDF
  /// contoh: "Oli Mesin (diganti), V-Belt (dibersihkan), Roller (diganti)"
  static String formatItemsSummary(List<ServiceItem> items, {bool includeBrand = false}) {
    if (items.isEmpty) return '-';
    return items
        .map((item) => includeBrand ? item.formattedSummary : item.shortSummary)
        .join(', ');
  }

  /// Memformat angka harga rupiah ke string mata uang Indonesia (id_ID),
  /// contoh: 145000 -> "Rp 145.000"
  static String formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Memformat tanggal ke format ramah Indonesia (id_ID),
  /// contoh: DateTime(2025, 3, 15) -> "15 Mar 2025"
  static String formatDate(DateTime date) {
    try {
      final formatter = DateFormat('d MMM yyyy', 'id_ID');
      return formatter.format(date);
    } catch (_) {
      final formatter = DateFormat('d MMM yyyy');
      return formatter.format(date);
    }
  }

  /// Memformat tanggal lengkap dalam bahasa Indonesia (id_ID),
  /// contoh: DateTime(2025, 3, 15) -> "15 Maret 2025"
  static String formatFullDate(DateTime date) {
    try {
      final formatter = DateFormat('d MMMM yyyy', 'id_ID');
      return formatter.format(date);
    } catch (_) {
      final formatter = DateFormat('d MMMM yyyy');
      return formatter.format(date);
    }
  }

  /// Mengurai string input biaya (misal "145.000" atau "Rp 145.000") menjadi bilangan bulat integer rupiah.
  /// Mengembalikan null jika input kosong atau tidak valid.
  static int? parseRupiahInput(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  /// Memformat angka kilometer dengan pemisah ribuan titik (id_ID),
  /// contoh: 14280 -> "14.280"
  static String formatKm(int km) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return formatter.format(km);
  }
}
