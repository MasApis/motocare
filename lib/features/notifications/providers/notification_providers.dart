import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/red_zone_calculator.dart';
import '../../odometer/providers/odometer_providers.dart';
import '../../vehicles/data/models/vehicle_component_model.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../data/notification_service.dart';

/// Provider singleton NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// State status izin notifikasi (true: diizinkan, false: belum/ditolak)
class NotificationPermissionNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    _checkPermission();
    return const AsyncValue.loading();
  }

  Future<void> _checkPermission() async {
    final service = ref.read(notificationServiceProvider);
    try {
      final granted = await service.isPermissionGranted();
      state = AsyncValue.data(granted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Meminta izin notifikasi ke sistem
  Future<bool> requestPermission() async {
    final service = ref.read(notificationServiceProvider);
    try {
      final granted = await service.requestPermission();
      state = AsyncValue.data(granted);
      return granted;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final notificationPermissionProvider =
    NotifierProvider<NotificationPermissionNotifier, AsyncValue<bool>>(
  NotificationPermissionNotifier.new,
);

/// Manager penjadwalan dan sinkronisasi notifikasi F6
class NotificationScheduler {
  NotificationScheduler(this._ref);

  final Ref _ref;

  NotificationService get _service => _ref.read(notificationServiceProvider);

  // Set untuk menyimpan track komponen yang sudah memicu notifikasi langsung pada KM tertentu
  // Format key: "vehicleId_componentType_km"
  static final Set<String> _immediateNotifiedKeys = {};

  /// Menjadwalkan ulang notifikasi untuk seluruh komponen pada kendaraan tertentu
  Future<void> syncNotificationsForVehicle({
    required Vehicle vehicle,
    required List<VehicleComponent> components,
    required double dailyAverageKm,
  }) async {
    // Pastikan service terinisialisasi
    await _service.initialize();

    for (final comp in components) {
      final isRed = calculateKmToRedZone(
        intervalKm: comp.intervalKm,
        currentKm: vehicle.currentKm,
        lastServiceKm: comp.lastServiceKm,
      ) <= 0;

      if (isRed) {
        // Jika komponen sudah merah
        final notificationKey = '${vehicle.id}_${comp.type}_${vehicle.currentKm}';
        // Tampilkan langsung sekali per komponen sampai di-reset (KM berubah atau servis dicatat)
        if (!_immediateNotifiedKeys.contains(notificationKey)) {
          _immediateNotifiedKeys.add(notificationKey);
          await _service.showImmediateRedZoneNotification(
            vehicleId: vehicle.id,
            vehicleName: vehicle.displayName,
            componentType: comp.type,
          );
        }
      } else {
        // Jika belum merah, hitung tanggal masuk zona merah
        final redZoneDate = calculateRedZoneDate(
          intervalKm: comp.intervalKm,
          currentKm: vehicle.currentKm,
          lastServiceKm: comp.lastServiceKm,
          dailyAverageKm: dailyAverageKm,
        );

        await _service.scheduleRedZoneNotification(
          vehicleId: vehicle.id,
          vehicleName: vehicle.displayName,
          componentType: comp.type,
          redZoneDate: redZoneDate,
        );
      }
    }
  }

  /// Menjadwalkan ulang untuk kendaraan aktif yang sedang dimuat
  Future<void> syncSelectedVehicleNotifications() async {
    final vehicle = _ref.read(selectedVehicleProvider);
    if (vehicle == null) return;

    final componentsAsync = _ref.read(selectedVehicleComponentsProvider);
    final components = componentsAsync.asData?.value ?? [];
    if (components.isEmpty) return;

    final avgKm = _ref.read(selectedVehicleDailyAverageKmProvider);

    await syncNotificationsForVehicle(
      vehicle: vehicle,
      components: components,
      dailyAverageKm: avgKm,
    );
  }

  /// Membatalkan seluruh notifikasi untuk kendaraan tertentu (misal saat dihapus)
  Future<void> cancelForVehicle(String vehicleId) async {
    await _service.cancelAllForVehicle(vehicleId);
  }

  /// Mode Uji Coba Sementara (5 detik)
  Future<void> triggerTestNotification(String vehicleName) async {
    await _service.scheduleTestNotification(
      vehicleName: vehicleName,
      componentName: 'Oli Mesin',
      delaySeconds: 5,
    );
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref);
});
