import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/service_calculator.dart';
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
          .snapshots()
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

  /// Menyimpan catatan servis baru sesuai docs/SPEC.md F5:
  /// - Data masuk ke `serviceRecords`
  /// - `lastServiceKm` pada komponen yang diservis diisi dengan KM servis
  /// - Jika KM servis melebihi currentKm motor, currentKm ikut diperbarui
  Future<String> addServiceRecord({
    required String vehicleId,
    required String componentType,
    required DateTime date,
    required int km,
    required String brand,
    required int price,
    required String location,
    String? note,
  }) async {
    try {
      if (km < 0) {
        throw const ServiceException('Kilometer servis tidak boleh negatif.');
      }
      if (brand.trim().isEmpty) {
        throw const ServiceException('Merek suku cadang atau oli wajib diisi.');
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
      final compDoc = _componentsRef(vehicleId, uid).doc(componentType);

      final record = ServiceRecord(
        id: newRecordDoc.id,
        vehicleId: vehicleId,
        componentType: componentType,
        date: date,
        km: km,
        brand: brand.trim(),
        price: price,
        location: location.trim(),
        note: note?.trim(),
        createdAt: DateTime.now(),
      );

      final batch = _firestore.batch();

      // 1. Tambah data riwayat servis
      batch.set(newRecordDoc, record.toMap());

      // 2. Perbarui lastServiceKm pada dokumen komponen sehingga kartu kembali 100%
      batch.set(compDoc, {
        'type': componentType,
        'lastServiceKm': km,
      }, SetOptions(merge: true));

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

      await batch.commit();
      return newRecordDoc.id;
    } on FirebaseException catch (e) {
      throw ServiceException(e.message ?? 'Gagal menyimpan catatan servis.');
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Terjadi kesalahan: $e');
    }
  }

  /// Menghapus catatan servis (dengan konfirmasi di UI)
  /// dan memperbarui kartu komponen agar kembali menghitung dari servis sebelumnya
  /// sesuai docs/SPEC.md F5.
  Future<void> deleteServiceRecord({
    required String vehicleId,
    required String recordId,
    required String componentType,
    int? vehicleInitialKm,
  }) async {
    try {
      final uid = _getRequiredUid();
      final vehicleDocRef = _vehicleDoc(vehicleId, uid);
      final recordDoc = _serviceRecordsRef(vehicleId, uid).doc(recordId);
      final compDoc = _componentsRef(vehicleId, uid).doc(componentType);

      // 1. Hapus dokumen catatan servis
      await recordDoc.delete();

      // 2. Ambil seluruh sisa catatan servis untuk komponen ini pada motor ini
      final remainingQuery = await _serviceRecordsRef(vehicleId, uid)
          .where('componentType', isEqualTo: componentType)
          .get();

      final remainingKms = remainingQuery.docs
          .map((d) => (d.data()['km'] as num?)?.toInt() ?? 0)
          .toList();

      // Baseline KM jika sudah tidak ada servis tersisa
      int baselineKm = vehicleInitialKm ?? 0;
      if (vehicleInitialKm == null) {
        final vehicleSnap = await vehicleDocRef.get();
        // Cek log odometer pertama untuk baseline awal motor
        final initialOdo = await vehicleDocRef
            .collection('odometerLogs')
            .orderBy('date', descending: false)
            .limit(1)
            .get();

        if (initialOdo.docs.isNotEmpty) {
          baselineKm = (initialOdo.docs.first.data()['km'] as num?)?.toInt() ?? 0;
        } else {
          baselineKm = (vehicleSnap.data()?['currentKm'] as num?)?.toInt() ?? 0;
        }
      }

      // 3. Hitung lastServiceKm baru dari servis sebelumnya menggunakan kalkulator inti
      final newLastServiceKm = ServiceCalculator.calculateLastServiceKmAfterDelete(
        initialKm: baselineKm,
        remainingServiceKms: remainingKms,
      );

      // 4. Update lastServiceKm pada dokumen komponen
      await compDoc.set({
        'type': componentType,
        'lastServiceKm': newLastServiceKm,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServiceException(e.message ?? 'Gagal menghapus catatan servis.');
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Terjadi kesalahan: $e');
    }
  }
}
