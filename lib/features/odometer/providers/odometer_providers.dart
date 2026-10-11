import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/odometer_calculator.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../data/models/odometer_log_model.dart';
import '../data/odometer_repository.dart';

/// Provider instance OdometerRepository
final odometerRepositoryProvider = Provider<OdometerRepository>((ref) {
  return OdometerRepository();
});

/// Stream catatan log odometer untuk kendaraan tertentu
final odometerLogsStreamProvider =
    StreamProvider.family<List<OdometerLog>, String>((ref, vehicleId) {
  final repository = ref.watch(odometerRepositoryProvider);
  return repository.watchOdometerLogs(vehicleId);
});

/// Stream catatan log odometer untuk motor yang sedang aktif terpilih di dashboard
final selectedVehicleOdometerLogsProvider =
    StreamProvider<List<OdometerLog>>((ref) {
  final activeVehicle = ref.watch(selectedVehicleProvider);
  if (activeVehicle == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(odometerRepositoryProvider);
  return repository.watchOdometerLogs(activeVehicle.id);
});

/// Provider perhitungan rata-rata KM harian (± X km/hari) untuk kendaraan aktif
final selectedVehicleDailyAverageKmProvider = Provider<double>((ref) {
  final logsAsync = ref.watch(selectedVehicleOdometerLogsProvider);
  final logs = logsAsync.asData?.value ?? [];
  final entries = logs.map((l) => l.toOdometerEntry()).toList();
  return calculateDailyAverageKm(entries);
});

/// Controller untuk menangani input dan pembaruan angka odometer
class OdometerController {
  OdometerController(this._ref);

  final Ref _ref;

  OdometerRepository get _repository => _ref.read(odometerRepositoryProvider);

  /// Menyimpan log odometer baru dan memperbarui currentKm kendaraan
  Future<String> updateOdometer({
    required String vehicleId,
    required int km,
    required DateTime date,
  }) async {
    return _repository.addOdometerLog(
      vehicleId: vehicleId,
      km: km,
      date: date,
    );
  }
}

final odometerControllerProvider = Provider<OdometerController>((ref) {
  return OdometerController(ref);
});
