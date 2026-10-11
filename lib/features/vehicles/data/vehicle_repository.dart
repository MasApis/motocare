import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/vehicle_components.dart';
import 'models/vehicle_component_model.dart';
import 'models/vehicle_model.dart';

class VehicleException implements Exception {
  const VehicleException(this.message);
  final String message;

  @override
  String toString() => message;
}

class VehicleRepository {
  VehicleRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _getRequiredUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const VehicleException('Pengguna belum masuk. Silakan masuk terlebih dahulu.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _vehiclesRef([String? uid]) {
    final currentUid = uid ?? _getRequiredUid();
    return _firestore.collection('users').doc(currentUid).collection('vehicles');
  }

  CollectionReference<Map<String, dynamic>> _componentsRef(String vehicleId, [String? uid]) {
    return _vehiclesRef(uid).doc(vehicleId).collection('components');
  }

  /// Menambahkan motor baru beserta 3 komponen default otomatis (SPEC F2 & SPEC 2.1)
  Future<String> addVehicle({
    required String brand,
    required String model,
    String? name,
    String? plate,
    required int currentKm,
    Map<String, int>? customIntervals,
  }) async {
    try {
      final uid = _getRequiredUid();
      final vehiclesCol = _vehiclesRef(uid);
      final newVehicleDoc = vehiclesCol.doc();
      final vehicleId = newVehicleDoc.id;

      final now = DateTime.now();
      final finalName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : '$brand $model'.trim();

      final vehicle = Vehicle(
        id: vehicleId,
        name: finalName,
        brand: brand.trim(),
        model: model.trim(),
        plate: plate?.trim(),
        currentKm: currentKm < 0 ? 0 : currentKm,
        createdAt: now,
      );

      final batch = _firestore.batch();
      // 1. Simpan dokumen kendaraan
      batch.set(newVehicleDoc, vehicle.toMap());

      // 2. Buat otomatis 3 komponen default
      final defaultComponents = createDefaultComponents(vehicle.currentKm);
      final componentsCol = _componentsRef(vehicleId, uid);

      for (final comp in defaultComponents) {
        final interval = customIntervals?[comp.type] ?? comp.intervalKm;
        final compDoc = componentsCol.doc(comp.type);
        batch.set(compDoc, {
          'type': comp.type,
          'intervalKm': interval,
          'lastServiceKm': comp.lastServiceKm,
        });
      }

      await batch.commit();
      return vehicleId;
    } on FirebaseException catch (e) {
      throw VehicleException(e.message ?? 'Gagal menambahkan motor.');
    } catch (e) {
      if (e is VehicleException) rethrow;
      throw VehicleException('Terjadi kesalahan: $e');
    }
  }

  /// Memperbarui informasi motor
  Future<void> updateVehicle({
    required String vehicleId,
    required String brand,
    required String model,
    String? name,
    String? plate,
    int? currentKm,
  }) async {
    try {
      final uid = _getRequiredUid();
      final vehicleDoc = _vehiclesRef(uid).doc(vehicleId);

      final finalName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : '$brand $model'.trim();

      final dataToUpdate = <String, dynamic>{
        'brand': brand.trim(),
        'model': model.trim(),
        'name': finalName,
        'plate': plate != null && plate.trim().isNotEmpty ? plate.trim() : FieldValue.delete(),
      };

      if (currentKm != null && currentKm >= 0) {
        dataToUpdate['currentKm'] = currentKm;
      }

      await vehicleDoc.update(dataToUpdate);
    } on FirebaseException catch (e) {
      throw VehicleException(e.message ?? 'Gagal memperbarui data motor.');
    } catch (e) {
      if (e is VehicleException) rethrow;
      throw VehicleException('Terjadi kesalahan: $e');
    }
  }

  /// Mengubah interval komponen tertentu per motor
  Future<void> updateComponentInterval({
    required String vehicleId,
    required String componentType,
    required int intervalKm,
  }) async {
    try {
      if (intervalKm <= 0) {
        throw const VehicleException('Interval harus lebih besar dari 0 km.');
      }
      final uid = _getRequiredUid();
      final compDoc = _componentsRef(vehicleId, uid).doc(componentType);

      await compDoc.set({
        'type': componentType,
        'intervalKm': intervalKm,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw VehicleException(e.message ?? 'Gagal memperbarui interval komponen.');
    } catch (e) {
      if (e is VehicleException) rethrow;
      throw VehicleException('Terjadi kesalahan: $e');
    }
  }

  /// Menghapus motor beserta seluruh subkoleksinya sesuai SPEC bagian 4
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      final uid = _getRequiredUid();
      final vehicleDoc = _vehiclesRef(uid).doc(vehicleId);

      // Hapus dokumen di subkoleksi components
      final componentsSnap = await _componentsRef(vehicleId, uid).get();
      // Hapus dokumen di subkoleksi odometerLogs
      final odometerSnap = await vehicleDoc.collection('odometerLogs').get();
      // Hapus dokumen di subkoleksi serviceRecords
      final serviceSnap = await vehicleDoc.collection('serviceRecords').get();

      final batch = _firestore.batch();
      for (final doc in componentsSnap.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in odometerSnap.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in serviceSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(vehicleDoc);

      await batch.commit();
    } on FirebaseException catch (e) {
      throw VehicleException(e.message ?? 'Gagal menghapus motor.');
    } catch (e) {
      if (e is VehicleException) rethrow;
      throw VehicleException('Terjadi kesalahan: $e');
    }
  }

  /// Stream daftar motor milik pengguna yang login saat ini
  Stream<List<Vehicle>> watchVehicles() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _vehiclesRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Vehicle.fromFirestore(doc)).toList();
    });
  }

  /// Stream daftar komponen untuk motor tertentu
  Stream<List<VehicleComponent>> watchComponents(String vehicleId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _componentsRef(vehicleId, uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleComponent.fromFirestore(doc))
          .toList();
    });
  }

  /// Mengambil data satu motor
  Future<Vehicle?> getVehicle(String vehicleId) async {
    try {
      final uid = _getRequiredUid();
      final doc = await _vehiclesRef(uid).doc(vehicleId).get();
      if (!doc.exists) return null;
      return Vehicle.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }
}
