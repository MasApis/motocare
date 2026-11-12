import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connection_checker.dart';

/// Status koneksi internet untuk badge di layar chat.
enum ConnectionStatus { checking, online, offline }

/// Pemeriksa koneksi. Diganti versi palsu saat pengujian.
final connectionCheckerProvider = Provider<ConnectionChecker>(
  (ref) => const ConnectionChecker(),
);

/// Notifier status koneksi; perbarui lewat [refresh].
class ConnectionStatusNotifier extends Notifier<ConnectionStatus> {
  @override
  ConnectionStatus build() => ConnectionStatus.checking;

  Future<void> refresh() async {
    final online = await ref.read(connectionCheckerProvider).isOnline();
    if (!ref.mounted) return;
    state = online ? ConnectionStatus.online : ConnectionStatus.offline;
  }
}

final connectionStatusProvider =
    NotifierProvider<ConnectionStatusNotifier, ConnectionStatus>(
  ConnectionStatusNotifier.new,
);
