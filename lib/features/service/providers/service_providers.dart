import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/service_calculator.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../data/models/service_record_model.dart';
import '../data/service_repository.dart';

/// Provider untuk instance ServiceRepository
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository();
});

/// Stream catatan servis untuk kendaraan spesifik
final serviceRecordsStreamProvider =
    StreamProvider.family<List<ServiceRecord>, String>((ref, vehicleId) {
  if (vehicleId.isEmpty) return Stream.value([]);
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.watchServiceRecords(vehicleId);
});

/// Notifier filter kendaraan di layar riwayat servis (null = Semua Motor)
class ServiceFilterVehicleIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? vehicleId) {
    state = vehicleId;
  }
}

final serviceFilterVehicleIdProvider =
    NotifierProvider<ServiceFilterVehicleIdNotifier, String?>(
  ServiceFilterVehicleIdNotifier.new,
);

/// Stream gabungan seluruh catatan servis dari seluruh motor milik pengguna
final allServiceRecordsStreamProvider = StreamProvider<List<ServiceRecord>>((ref) {
  final vehiclesAsync = ref.watch(vehiclesStreamProvider);
  final vehicles = vehiclesAsync.asData?.value ?? [];

  if (vehicles.isEmpty) {
    return Stream.value([]);
  }

  final repo = ref.watch(serviceRepositoryProvider);
  final controller = StreamController<List<ServiceRecord>>();
  final latestMap = <String, List<ServiceRecord>>{};
  final subscriptions = <StreamSubscription<List<ServiceRecord>>>[];

  void emitMerged() {
    final allList = <ServiceRecord>[];
    for (final list in latestMap.values) {
      allList.addAll(list);
    }
    // Urutkan dari yang terbaru ke terlama
    allList.sort((a, b) => b.date.compareTo(a.date));
    if (!controller.isClosed) {
      controller.add(allList);
    }
  }

  for (final v in vehicles) {
    final sub = repo.watchServiceRecords(v.id).listen(
      (records) {
        latestMap[v.id] = records;
        emitMerged();
      },
      onError: (Object err) {
        if (!controller.isClosed) {
          controller.addError(err);
        }
      },
    );
    subscriptions.add(sub);
  }

  ref.onDispose(() {
    for (final s in subscriptions) {
      s.cancel();
    }
    controller.close();
  });

  return controller.stream;
});

/// Catatan servis yang telah disaring berdasarkan pilihan filter kendaraan
final filteredServiceRecordsProvider = Provider<AsyncValue<List<ServiceRecord>>>((ref) {
  final filterVehicleId = ref.watch(serviceFilterVehicleIdProvider);

  if (filterVehicleId != null && filterVehicleId.isNotEmpty) {
    return ref.watch(serviceRecordsStreamProvider(filterVehicleId));
  } else {
    return ref.watch(allServiceRecordsStreamProvider);
  }
});

/// State controller untuk aksi simpan & hapus servis
class ServiceControllerState {
  const ServiceControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  ServiceControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ServiceControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ServiceController extends Notifier<ServiceControllerState> {
  @override
  ServiceControllerState build() => const ServiceControllerState();

  Future<bool> addServiceRecord({
    required String vehicleId,
    required List<ServiceItem> items,
    required DateTime date,
    required int km,
    required int price,
    required String location,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(serviceRepositoryProvider);
      await repo.addServiceRecord(
        vehicleId: vehicleId,
        items: items,
        date: date,
        km: km,
        price: price,
        location: location,
        note: note,
      );

      // Sinkronkan ulang jadwal notifikasi
      unawaited(
        ref.read(notificationSchedulerProvider).syncSelectedVehicleNotifications(),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Catatan servis berhasil disimpan.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteServiceRecord({
    required String vehicleId,
    required String recordId,
    int? vehicleInitialKm,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(serviceRepositoryProvider);
      await repo.deleteServiceRecord(
        vehicleId: vehicleId,
        recordId: recordId,
        vehicleInitialKm: vehicleInitialKm,
      );

      // Sinkronkan ulang jadwal notifikasi
      unawaited(
        ref.read(notificationSchedulerProvider).syncSelectedVehicleNotifications(),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Catatan servis berhasil dihapus.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final serviceControllerProvider =
    NotifierProvider<ServiceController, ServiceControllerState>(
  ServiceController.new,
);
