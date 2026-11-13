import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/save_status.dart';
import '../../../../core/service_calculator.dart';
import '../../../../core/vehicle_components.dart';
import 'models/service_record_model.dart';

class ServiceException implements Exception {
  const ServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Repository untuk mengelola catatan servis di subkoleksi:
/// `users/{uid}/vehicles/{vehicleId}/serviceRecords`
class ServiceRepository {
  ServiceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _getRequiredUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ServiceException('Pengguna belum masuk. Silakan masuk terlebih dahulu.');
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

  CollectionReference<Map<String, dynamic>> _serviceRecordsRef(String vehicleId, [String? uid]) {
    return _vehicleDoc(vehicleId, uid).collection('serviceRecords');
  }

  CollectionReference<Map<String, dynamic>> _componentsRef(String vehicleId, [String? uid]) {
    return _vehicleDoc(vehicleId, uid).collection('components');
  }

  /// Memantau daftar catatan riwayat servis kendaraan tertentu secara realtime (terbaru dulu)
  Stream<List<ServiceRecord>> watchServiceRecords(String vehicleId) {
    try {
      final uid = _getRequiredUid();
      return _serviceRecordsRef(vehicleId, uid)
          .orderBy('date', descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ServiceRecord.fromFirestore(doc, fallbackVehicleId: vehicleId))
            .toList();
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Mengambil daftar catatan servis untuk kendaraan tertentu
  Future<List<ServiceRecord>> getServiceRecords(String vehicleId) async {
    try {
      final uid = _getRequiredUid();
      final snapshot = await _serviceRecordsRef(vehicleId, uid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ServiceRecord.fromFirestore(doc, fallbackVehicleId: vehicleId))
          .toList();
    } on FirebaseException catch (e) {
      throw ServiceException(e.message ?? 'Gagal memuat riwayat servis.');
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Terjadi kesalahan: $e');
    }
  }

  /// Menyimpan catatan servis baru sesuai docs/SPEC.md Bagian 2.1 & F5:
  /// - Data masuk ke `serviceRecords` dengan struktur `items[]`
  /// - Hanya komponen yang "replaced" (diganti) yang mereset kartunya (`lastServiceKm = km`)
  /// - Komponen yang "cleaned" atau part lain tidak mengubah kartu komponen
  /// - Jika KM servis melebihi currentKm motor, currentKm ikut diperbarui
  Future<SaveResult<String>> addServiceRecord({
    required String vehicleId,
    required List<ServiceItem> items,
    required DateTime date,
    required int km,
    required int price,
    required String location,
    String? note,
  }) async {
    try {
      if (km < 0) {
        throw const ServiceException('Kilometer servis tidak boleh negatif.');
      }
      if (items.isEmpty) {
        throw const ServiceException('Minimal satu pekerjaan atau item servis harus dipilih / diisi.');
      }
      for (final item in items) {
        if (item.kind == ServiceItemKind.part &&
            (item.name == null || item.name!.trim().isEmpty)) {
          throw const ServiceException('Nama suku cadang pada part lain wajib diisi.');
        }
      }
      if (location.trim().isEmpty) {
        throw const ServiceException('Nama bengkel atau lokasi servis wajib diisi.');
      }
      if (price < 0) {
        throw const ServiceException('Biaya servis tidak boleh negatif.');
      }

      final uid = _getRequiredUid();
      final vehicleDocRef = _vehicleDoc(vehicleId, uid);
      final newRecordDoc = _serviceRecordsRef(vehicleId, uid).doc();

      final record = ServiceRecord(
        id: newRecordDoc.id,
        vehicleId: vehicleId,
        items: items,
        date: date,
        km: km,
        price: price,
        location: location.trim(),
        note: note?.trim(),
        createdAt: DateTime.now(),
      );

      final batch = _firestore.batch();

      // 1. Tambah data riwayat servis
      batch.set(newRecordDoc, record.toMap());

      // 2. Perbarui lastServiceKm HANYA pada komponen yang diganti (replaced)
      final componentsToReset = ServiceCalculator.getComponentsToReset(items);
      for (final compType in componentsToReset) {
        final compDoc = _componentsRef(vehicleId, uid).doc(compType);
        batch.set(compDoc, {
          'type': compType,
          'lastServiceKm': km,
          // Reset penanda notifikasi: komponen yang baru diservis harus bisa
          // memberi peringatan lagi saat masuk zona merah berikutnya.
          'lastRedNotifiedKm': null,
        }, SetOptions(merge: true));
      }

      // 3. Cek apakah KM servis lebih tinggi dari currentKm motor
      final vehicleSnap = await vehicleDocRef.get();
      final currentVehicleKm = (vehicleSnap.data()?['currentKm'] as num?)?.toInt() ?? 0;
      if (km > currentVehicleKm) {
        batch.update(vehicleDocRef, {'currentKm': km});

        // Tambah log odometer baru
        final odoDoc = vehicleDocRef.collection('odometerLogs').doc();
        batch.set(odoDoc, {
          'km': km,
          'date': Timestamp.fromDate(date),
        });
      }

      final status = await awaitServerAck(batch.commit());
      return (value: newRecordDoc.id, status: status);
    } on FirebaseException catch (e) {
      throw ServiceException(e.message ?? 'Gagal menyimpan catatan servis.');
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Terjadi kesalahan: $e');
    }
  }

  /// Menghapus catatan servis (dengan konfirmasi di UI)
  /// dan memperbarui kartu komponen agar kembali menghitung dari servis sebelumnya
  /// atau kembali ke baselineKm sesuai docs/SPEC.md Bagian 2.1 & F5.
  Future<SaveStatus> deleteServiceRecord({
    required String vehicleId,
    required String recordId,
    int? vehicleInitialKm,
  }) async {
    try {
      final uid = _getRequiredUid();
      final vehicleDocRef = _vehicleDoc(vehicleId, uid);
      final recordsRef = _serviceRecordsRef(vehicleId, uid);
      final recordDoc = recordsRef.doc(recordId);

      // Semua pembacaan dilakukan dulu. Penghapusan dan hitung ulang komponen
      // ditulis dalam satu batch, supaya tidak ada kondisi catatan sudah hilang
      // tetapi lastServiceKm masih menunjuk servis yang sudah dihapus.
      final remainingDocs = await recordsRef.get();
      final remainingSummaries = remainingDocs.docs
          .where((doc) => doc.id != recordId)
          .map((doc) => ServiceRecord.fromFirestore(
                doc,
                fallbackVehicleId: vehicleId,
              ).toSummary())
          .toList();

      final componentsSnap = await _componentsRef(vehicleId, uid).get();
      int? vehicleKm;

      final batch = _firestore.batch();
      batch.delete(recordDoc);

      for (final compType in ComponentType.values) {
        final compDoc = _componentsRef(vehicleId, uid).doc(compType);
        final compDocSnap =
            componentsSnap.docs.where((d) => d.id == compType).firstOrNull;

        int baselineKm = 0;
        if (compDocSnap != null && compDocSnap.data().containsKey('baselineKm')) {
          baselineKm = (compDocSnap.data()['baselineKm'] as num?)?.toInt() ?? 0;
        } else if (vehicleInitialKm != null) {
          baselineKm = vehicleInitialKm;
        } else {
          if (vehicleKm == null) {
            final vehicleSnap = await vehicleDocRef.get();
            vehicleKm = (vehicleSnap.data()?['currentKm'] as num?)?.toInt() ?? 0;
          }
          baselineKm = vehicleKm;
        }

        final newLastServiceKm =
            ServiceCalculator.calculateComponentLastServiceKmAfterDelete(
          componentType: compType,
          baselineKm: baselineKm,
          remainingRecords: remainingSummaries,
        );

        batch.set(compDoc, {
          'type': compType,
          'lastServiceKm': newLastServiceKm,
          'baselineKm': baselineKm,
          // Hitung ulang setelah penghapusan, jadi penanda notifikasi ikut direset.
          'lastRedNotifiedKm': null,
        }, SetOptions(merge: true));
      }

      final status = await awaitServerAck(batch.commit());
      return status;
    } on FirebaseException catch (e) {
      throw ServiceException(e.message ?? 'Gagal menghapus catatan servis.');
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Terjadi kesalahan: $e');
    }
  }
}
