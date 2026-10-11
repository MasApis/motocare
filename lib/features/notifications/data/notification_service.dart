import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/vehicle_components.dart';

/// Service untuk menangani notifikasi lokal Android sesuai F6 docs/SPEC.md
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _plugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  /// Channel ID untuk notifikasi pengingat servis MotoCare
  static const String channelId = 'motocare_service_alerts';
  static const String channelName = 'Pengingat Servis MotoCare';
  static const String channelDescription =
      'Notifikasi pengingat ketika komponen motor mencapai batas usia pakai';

  /// Inisialisasi timezone dan konfigurasi Android notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inisialisasi database timezone
    tz.initializeTimeZones();
    // Default fallback local location
    try {
      final now = DateTime.now();
      final offsetInMilliseconds = now.timeZoneOffset.inMilliseconds;
      final locationName = tz.timeZoneDatabase.locations.entries
          .firstWhere(
            (entry) => entry.value.currentTimeZone.offset == offsetInMilliseconds,
            orElse: () => tz.timeZoneDatabase.locations.entries.first,
          )
          .key;
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Jika penentuan nama zona gagal, gunakan UTC/default yang tersedia
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notifikasi diklik: ${response.payload}');
      },
    );

    // Buat Notification Channel khusus Android dengan prioritas tinggi
    final androidNotificationPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
      );
      await androidNotificationPlugin.createNotificationChannel(channel);
    }

    _isInitialized = true;
  }

  /// Meminta izin notifikasi ke pengguna (terutama Android 13+)
  /// Mengembalikan true jika diizinkan, false jika ditolak.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    try {
      final granted = await androidPlugin.requestNotificationsPermission();
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (_) {}
      return granted ?? false;
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');
      return false;
    }
  }

  /// Mengecek apakah izin notifikasi aktif saat ini
  Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    try {
      final enabled = await androidPlugin.areNotificationsEnabled();
      return enabled ?? false;
    } catch (e) {
      debugPrint('Gagal memeriksa status izin notifikasi: $e');
      return false;
    }
  }

  /// Menghasilkan Notification ID unik integer stabil per kendaraan dan tipe komponen
  int generateNotificationId(String vehicleId, String componentType) {
    int componentOffset;
    switch (componentType) {
      case 'engine_oil':
        componentOffset = 1;
        break;
      case 'gear_oil':
        componentOffset = 2;
        break;
      case 'v_belt':
        componentOffset = 3;
        break;
      default:
        componentOffset = 0;
    }
    // Kombinasi hash vehicleId dan offset komponen (dalam rentang integer 31-bit)
    return (vehicleId.hashCode.abs() % 100000) * 10 + componentOffset;
  }

  /// Membatalkan notifikasi lama yang terjadwal untuk komponen tertentu
  Future<void> cancelNotification(String vehicleId, String componentType) async {
    final id = generateNotificationId(vehicleId, componentType);
    await _plugin.cancel(id);
    debugPrint('Membatalkan notifikasi ID $id ($componentType)');
  }

  /// Membatalkan semua notifikasi dari suatu kendaraan (misal saat motor dihapus)
  Future<void> cancelAllForVehicle(String vehicleId) async {
    for (final type in ['engine_oil', 'gear_oil', 'v_belt']) {
      await cancelNotification(vehicleId, type);
    }
  }

  /// Menampilkan notifikasi langsung saat komponen sudah masuk zona merah (< 10%)
  Future<void> showImmediateRedZoneNotification({
    required String vehicleId,
    required String vehicleName,
    required String componentType,
  }) async {
    await initialize();
    final id = generateNotificationId(vehicleId, componentType);
    final componentName = ComponentType.getLabel(componentType);

    final title = '⚠️ Batas Habis: $componentName ($vehicleName)';
    final body =
        '$componentName pada motor $vehicleName sudah mencapai batas habis (<10%). Segera lakukan servis!';

    final bigTextStyle = BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: 'Peringatan MotoCare',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyle,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: '$vehicleId|$componentType',
    );
    debugPrint('Notifikasi langsung ditampilkan untuk ID $id');
  }

  /// Menjadwalkan notifikasi pada tanggal zona merah pukul 08:00 waktu lokal
  Future<void> scheduleRedZoneNotification({
    required String vehicleId,
    required String vehicleName,
    required String componentType,
    required DateTime redZoneDate,
  }) async {
    await initialize();
    final id = generateNotificationId(vehicleId, componentType);
    final componentName = ComponentType.getLabel(componentType);

    // Batalkan notifikasi lama terlebih dahulu agar tidak duplikat
    await _plugin.cancel(id);

    // Jadwalkan tepat pukul 08:00 waktu lokal
    final scheduledTzDate = tz.TZDateTime(
      tz.local,
      redZoneDate.year,
      redZoneDate.month,
      redZoneDate.day,
      8, // 08:00 pagi
      0,
      0,
    );

    final nowTz = tz.TZDateTime.now(tz.local);

    // Jika waktu jadwal sudah lewat dari sekarang, tampilkan notifikasi sekarang jika hari ini
    if (scheduledTzDate.isBefore(nowTz)) {
      final isToday = redZoneDate.year == nowTz.year &&
          redZoneDate.month == nowTz.month &&
          redZoneDate.day == nowTz.day;
      if (isToday) {
        await showImmediateRedZoneNotification(
          vehicleId: vehicleId,
          vehicleName: vehicleName,
          componentType: componentType,
        );
      }
      return;
    }

    final title = '⚠️ Waktunya Servis: $componentName ($vehicleName)';
    final body =
        '$componentName pada motor $vehicleName diprediksi mencapai batas habis hari ini. Periksa dan jadwalkan servis.';

    final bigTextStyle = BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: 'Pengingat MotoCare',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyle,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTzDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$vehicleId|$componentType',
      );
      debugPrint('Notifikasi dijadwalkan untuk ID $id pada $scheduledTzDate');
    } catch (e) {
      // Jika exact alarm ditolak oleh sistem, fallback ke inexact tanpa membuat aplikasi error
      debugPrint('Fallback ke inexact schedule: $e');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTzDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$vehicleId|$componentType',
      );
    }
  }

  /// Mode Uji Sementara (Bertanda jelas):
  /// Menjadwalkan notifikasi dalam 5 detik untuk pengujian langsung di HP fisik
  Future<void> scheduleTestNotification({
    required String vehicleName,
    required String componentName,
    int delaySeconds = 5,
  }) async {
    await initialize();
    const testId = 999999;

    final title = '🧪 [Uji Notifikasi] $componentName ($vehicleName)';
    final body =
        'Notifikasi uji berhasil muncul setelah $delaySeconds detik tanpa membuka aplikasi!';

    final bigTextStyle = BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: 'Uji Coba MotoCare',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyle,
    );

    // 1. Pasang jadwal via sistem Android
    final scheduledTzDate = tz.TZDateTime.now(tz.local).add(
      Duration(seconds: delaySeconds),
    );

    try {
      await _plugin.zonedSchedule(
        testId,
        title,
        body,
        scheduledTzDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Jadwal exact gagal, coba inexact: $e');
      try {
        await _plugin.zonedSchedule(
          testId,
          title,
          body,
          scheduledTzDate,
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (err) {
        debugPrint('Jadwal zonedSchedule error: $err');
      }
    }

    // 2. Tandem timer langsung di aplikasi agar pasti muncul tepat 5 detik
    // sekalipun sistem manajemen baterai HP Infinix menunda AlarmManager
    Future.delayed(Duration(seconds: delaySeconds), () async {
      try {
        await _plugin.show(
          testId,
          title,
          body,
          NotificationDetails(android: androidDetails),
        );
      } catch (_) {}
    });

    debugPrint('Uji notifikasi dijadwalkan dalam $delaySeconds detik');
  }
}

