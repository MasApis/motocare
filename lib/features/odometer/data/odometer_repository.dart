import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/odometer_log_model.dart';

class OdometerException implements Exception {
  const OdometerException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Repository untuk mengelola catatan odometer di subkoleksi:
/// `users/{uid}/vehicles/{vehicleId}/odometerLogs`
class OdometerRepository {
  OdometerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _getRequiredUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const OdometerException('Pengguna belum masuk. Silakan masuk terlebih dahulu.');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _vehicleDoc(String vehicleId, [String? uid]) {
    final currentUid = uid ?? _getRequiredUid();
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('vehicles')
        .doc(vehicleId);
  }

  CollectionReference<Map<String, dynamic>> _odometerLogsRef(String vehicleId, [String? uid]) {
    return _vehicleDoc(vehicleId, uid).collection('odometerLogs');
  }

  /// Memantau seluruh catatan log odometer untuk kendaraan tertentu secara realtime
  Stream<List<OdometerLog>> watchOdometerLogs(String vehicleId) {
    try {
      final uid = _getRequiredUid();
      return _odometerLogsRef(vehicleId, uid)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => OdometerLog.fromFirestore(doc))
            .toList();
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Mengambil daftar catatan log odometer secara asynchronous
  Future<List<OdometerLog>> getOdometerLogs(String vehicleId) async {
    try {
      final uid = _getRequiredUid();
      final snapshot = await _odometerLogsRef(vehicleId, uid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OdometerLog.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw OdometerException(e.message ?? 'Gagal memuat catatan odometer.');
    } catch (e) {
      if (e is OdometerException) rethrow;
      throw OdometerException('Terjadi kesalahan: $e');
    }
  }

  /// Menambahkan catatan odometer baru dan sekaligus memperbarui currentKm kendaraan
  /// sesuai docs/SPEC.md (F4 & 2.1)
  Future<String> addOdometerLog({
    required String vehicleId,
    required int km,
    required DateTime date,
  }) async {
    try {
      final uid = _getRequiredUid();
      final vehicleRef = _vehicleDoc(vehicleId, uid);
      final logsCol = _odometerLogsRef(vehicleId, uid);
      final newLogDoc = logsCol.doc();

      final batch = _firestore.batch();

      // 1. Tambahkan log baru ke subkoleksi odometerLogs
      batch.set(newLogDoc, {
        'km': km,
        'date': Timestamp.fromDate(date),
      });

      // 2. Perbarui currentKm pada dokumen kendaraan agar dashboard langsung berubah
      batch.update(vehicleRef, {
        'currentKm': km,
      });

      await batch.commit();
      return newLogDoc.id;
    } on FirebaseException catch (e) {
      throw OdometerException(e.message ?? 'Gagal menyimpan angka odometer.');
    } catch (e) {
      if (e is OdometerException) rethrow;
      throw OdometerException('Terjadi kesalahan: $e');
    }
  }
}
