import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/notifications/providers/notification_providers.dart';
import 'package:motocare/features/notifications/ui/notification_permission_banner.dart';

void main() {
  testWidgets('NotificationPermissionBanner tampil saat izin notifikasi belum diberikan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationPermissionProvider.overrideWith(
            () => _FakePermissionNotifier(false),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationPermissionBanner(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verifikasi pesan ramah dan penjelasan dampak tampil
    expect(find.text('Pengingat Servis Belum Aktif'), findsOneWidget);
    expect(
      find.textContaining('Izin notifikasi belum diaktifkan'),
      findsOneWidget,
    );
    expect(find.text('Aktifkan Notifikasi'), findsOneWidget);
  });

  testWidgets('NotificationPermissionBanner tersembunyi saat izin notifikasi sudah aktif', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationPermissionProvider.overrideWith(
            () => _FakePermissionNotifier(true),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationPermissionBanner(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verifikasi tidak ada widget peringatan yang tampil
    expect(find.text('Pengingat Servis Belum Aktif'), findsNothing);
    expect(find.text('Aktifkan Notifikasi'), findsNothing);
  });
}

class _FakePermissionNotifier extends NotificationPermissionNotifier {
  _FakePermissionNotifier(this._granted);

  final bool _granted;

  @override
  AsyncValue<bool> build() {
    return AsyncValue.data(_granted);
  }

  @override
  Future<bool> requestPermission() async {
    return _granted;
  }
}
