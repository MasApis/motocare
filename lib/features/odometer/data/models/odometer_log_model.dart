import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/odometer_calculator.dart';

/// Model catatan log odometer sesuai docs/SPEC.md bagian 4:
/// `odometerLogs/{id}: km, date`
class OdometerLog {
  const OdometerLog({
    required this.id,
    required this.km,
    required this.date,
    this.hasPendingWrites = false,
  });

  final String id;
  final int km;
  final DateTime date;

  /// True bila catatan masih menunggu dikirim ke server (disimpan di HP saja).
  final bool hasPendingWrites;

  /// Konversi ke entri murni [OdometerEntry] untuk kalkulasi di core/
  OdometerEntry toOdometerEntry() {
    return OdometerEntry(km: km, date: date);
  }

  Map<String, dynamic> toMap() {
    return {
      'km': km,
      'date': Timestamp.fromDate(date),
    };
  }

  factory OdometerLog.fromMap(Map<String, dynamic> map, String id, {bool hasPendingWrites = false}) {
    final rawDate = map['date'];
    final DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return OdometerLog(
      id: id,
      km: (map['km'] as num?)?.toInt() ?? 0,
      date: parsedDate,
      hasPendingWrites: hasPendingWrites,
    );
  }

  factory OdometerLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return OdometerLog.fromMap(
      doc.data() ?? {},
      doc.id,
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }

  OdometerLog copyWith({
    String? id,
    int? km,
    DateTime? date,
    bool? hasPendingWrites,
  }) {
    return OdometerLog(
      id: id ?? this.id,
      km: km ?? this.km,
      date: date ?? this.date,
      hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
    );
  }
}
