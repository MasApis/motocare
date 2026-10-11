import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/odometer_calculator.dart';
import '../../notifications/providers/notification_providers.dart';
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
  /// serta memicu penjadwalan ulang notifikasi F6 sesuai docs/SPEC.md
  Future<String> updateOdometer({
    required String vehicleId,
    required int km,
    required DateTime date,
  }) async {
    final logId = await _repository.addOdometerLog(
      vehicleId: vehicleId,
      km: km,
      date: date,
    );

    // Memicu perhitungan ulang notifikasi di background secara aman
    try {
      final vehicleRepo = _ref.read(vehicleRepositoryProvider);
      final vehicle = await vehicleRepo.getVehicle(vehicleId);
      if (vehicle != null) {
        final components = await vehicleRepo.getComponents(vehicleId);
        final logs = await _repository.getOdometerLogs(vehicleId);
        final entries = logs.map((l) => l.toOdometerEntry()).toList();
        final dailyAvg = calculateDailyAverageKm(entries);

        final scheduler = _ref.read(notificationSchedulerProvider);
        await scheduler.syncNotificationsForVehicle(
          vehicle: vehicle,
          components: components,
          dailyAverageKm: dailyAvg,
        );
      }
    } catch (_) {
      // Kegagalan penjadwalan notifikasi tidak boleh membatalkan penyimpanan odometer
    }

    return logId;
  }
}

final odometerControllerProvider = Provider<OdometerController>((ref) {
  return OdometerController(ref);
});
