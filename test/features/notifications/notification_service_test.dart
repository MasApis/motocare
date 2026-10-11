import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/notifications/data/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('NotificationService ID Generation Tests', () {
    final service = NotificationService();

    test('generateNotificationId menghasilkan ID deterministik dan unik per komponen', () {
      const vehicleId = 'vario_160_abc';

      final engineOilId = service.generateNotificationId(vehicleId, 'engine_oil');
      final gearOilId = service.generateNotificationId(vehicleId, 'gear_oil');
      final vBeltId = service.generateNotificationId(vehicleId, 'v_belt');

      // ID harus integer valid (positif)
      expect(engineOilId, isPositive);
      expect(gearOilId, isPositive);
      expect(vBeltId, isPositive);

      // ID antar komponen pada motor yang sama harus berbeda
      expect(engineOilId, isNot(equals(gearOilId)));
      expect(engineOilId, isNot(equals(vBeltId)));
      expect(gearOilId, isNot(equals(vBeltId)));

      // ID harus konsisten untuk input yang sama
      expect(service.generateNotificationId(vehicleId, 'engine_oil'), equals(engineOilId));
    });

    test('generateNotificationId membedakan motor yang berbeda', () {
      const vehicle1 = 'motor_1';
      const vehicle2 = 'motor_2';

      final id1 = service.generateNotificationId(vehicle1, 'engine_oil');
      final id2 = service.generateNotificationId(vehicle2, 'engine_oil');

      expect(id1, isNot(equals(id2)));
    });

    test('tz location detection test mengonfigurasi local timezone dengan benar', () {
      tz.initializeTimeZones();
      final now = DateTime.now();
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      final match = tz.timeZoneDatabase.locations.entries.firstWhere(
        (entry) => entry.value.currentTimeZone.offset == offsetMs,
        orElse: () => tz.timeZoneDatabase.locations.entries.first,
      );
      tz.setLocalLocation(match.value);
      final tzNow = tz.TZDateTime.now(tz.local);
      expect(tzNow.hour, equals(now.hour));
      expect(tzNow.minute, equals(now.minute));
    });
  });
}
