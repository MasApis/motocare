import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/vehicle_component_model.dart';
import '../data/models/vehicle_model.dart';
import '../data/vehicle_repository.dart';

/// Provider instance VehicleRepository
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});

/// Stream seluruh kendaraan pengguna
final vehiclesStreamProvider = StreamProvider<List<Vehicle>>((ref) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return repository.watchVehicles();
});

/// Notifier untuk menyimpan ID kendaraan yang dipilih di carousel / dashboard
class SelectedVehicleIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? vehicleId) {
    state = vehicleId;
  }
}

final selectedVehicleIdProvider =
    NotifierProvider<SelectedVehicleIdNotifier, String?>(
  SelectedVehicleIdNotifier.new,
);

/// Kendaraan aktif yang terpilih
final selectedVehicleProvider = Provider<Vehicle?>((ref) {
  final vehiclesAsync = ref.watch(vehiclesStreamProvider);
  final selectedId = ref.watch(selectedVehicleIdProvider);

  return vehiclesAsync.when(
    data: (vehicles) {
      if (vehicles.isEmpty) return null;
      if (selectedId == null) return vehicles.first;
      return vehicles.firstWhere(
        (v) => v.id == selectedId,
        orElse: () => vehicles.first,
      );
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Stream komponen untuk kendaraan tertentu
final vehicleComponentsStreamProvider =
    StreamProvider.family<List<VehicleComponent>, String>((ref, vehicleId) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return repository.watchComponents(vehicleId);
});

/// Stream komponen untuk kendaraan aktif
final selectedVehicleComponentsProvider =
    StreamProvider<List<VehicleComponent>>((ref) {
  final selectedVehicle = ref.watch(selectedVehicleProvider);
  if (selectedVehicle == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(vehicleRepositoryProvider);
  return repository.watchComponents(selectedVehicle.id);
});

/// Controller untuk mengeksekusi aksi penambahan, perubahan, dan penghapusan motor
class VehicleController {
  VehicleController(this._ref);

  final Ref _ref;

  VehicleRepository get _repository => _ref.read(vehicleRepositoryProvider);

  Future<String> addVehicle({
    required String brand,
    required String model,
    String? name,
    String? plate,
    required int currentKm,
    Map<String, int>? customIntervals,
  }) async {
    return _repository.addVehicle(
      brand: brand,
      model: model,
      name: name,
      plate: plate,
      currentKm: currentKm,
      customIntervals: customIntervals,
    );
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String brand,
    required String model,
    String? name,
    String? plate,
    int? currentKm,
    Map<String, int>? customIntervals,
  }) async {
    await _repository.updateVehicle(
      vehicleId: vehicleId,
      brand: brand,
      model: model,
      name: name,
      plate: plate,
      currentKm: currentKm,
    );

    if (customIntervals != null) {
      for (final entry in customIntervals.entries) {
        await _repository.updateComponentInterval(
          vehicleId: vehicleId,
          componentType: entry.key,
          intervalKm: entry.value,
        );
      }
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _repository.deleteVehicle(vehicleId);
  }

  Future<void> updateComponentInterval({
    required String vehicleId,
    required String componentType,
    required int intervalKm,
  }) async {
    await _repository.updateComponentInterval(
      vehicleId: vehicleId,
      componentType: componentType,
      intervalKm: intervalKm,
    );
  }
}

final vehicleControllerProvider = Provider<VehicleController>((ref) {
  return VehicleController(ref);
});
