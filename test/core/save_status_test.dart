import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/save_status.dart';

void main() {
  group('awaitServerAck', () {
    test('synced saat server mengonfirmasi sebelum batas waktu', () async {
      expect(await awaitServerAck(Future<void>.value()), SaveStatus.synced);
    });

    test('queued saat penyimpanan tidak selesai sampai batas waktu', () async {
      final never = Completer<void>().future;

      final status = await awaitServerAck(
        never,
        timeout: const Duration(milliseconds: 20),
      );

      expect(status, SaveStatus.queued);
    });

    test('melempar error asli jika penyimpanan gagal', () async {
      final failing = Future<void>.error(Exception('izin ditolak'));

      expect(
        () => awaitServerAck(failing),
        throwsA(isA<Exception>()),
      );
    });

    test('error yang datang setelah batas waktu tidak menjadi unhandled',
        () async {
      final completer = Completer<void>();

      final status = await awaitServerAck(
        completer.future,
        timeout: const Duration(milliseconds: 20),
      );
      expect(status, SaveStatus.queued);

      // Selesaikan dengan error setelah batas waktu; tidak boleh melempar
      // ke zona error global.
      completer.completeError(Exception('terlambat'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  });
}
