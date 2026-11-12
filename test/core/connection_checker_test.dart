import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/connection_checker.dart';

void main() {
  group('ConnectionChecker', () {
    test('online saat host ditemukan', () async {
      final checker = ConnectionChecker(
        lookup: (host) async => [InternetAddress('127.0.0.1')],
      );

      expect(await checker.isOnline(), isTrue);
    });

    test('offline saat hasil lookup kosong', () async {
      final checker = ConnectionChecker(lookup: (host) async => []);

      expect(await checker.isOnline(), isFalse);
    });

    test('offline saat lookup gagal (SocketException)', () async {
      final checker = ConnectionChecker(
        lookup: (host) async => throw SocketException('tidak ada jaringan'),
      );

      expect(await checker.isOnline(), isFalse);
    });

    test('offline saat lookup melebihi batas waktu', () async {
      final checker = ConnectionChecker(
        timeout: const Duration(milliseconds: 50),
        lookup: (host) => Completer<List<InternetAddress>>().future,
      );

      expect(await checker.isOnline(), isFalse);
    });
  });
}
