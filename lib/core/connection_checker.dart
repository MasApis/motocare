import 'dart:async';
import 'dart:io';

/// Batas waktu pemeriksaan koneksi.
const Duration connectionCheckTimeout = Duration(seconds: 3);

/// Fungsi pencarian alamat yang bisa diganti saat pengujian.
typedef HostLookup = Future<List<InternetAddress>> Function(String host);

/// Menentukan apakah perangkat bisa menjangkau internet.
///
/// Memakai DNS lookup bawaan Dart, bukan paket tambahan. Cukup untuk
/// membedakan "tidak ada internet" dari "ada internet"; koneksi yang
/// sangat lambat bisa terbaca offline karena batas waktu [timeout].
class ConnectionChecker {
  const ConnectionChecker({
    this.host = 'api.groq.com',
    this.timeout = connectionCheckTimeout,
    this.lookup,
  });

  final String host;
  final Duration timeout;
  final HostLookup? lookup;

  Future<bool> isOnline() async {
    try {
      final addresses = await (lookup ?? InternetAddress.lookup)(
        host,
      ).timeout(timeout);
      return addresses.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
