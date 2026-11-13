import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pembacaan/penulisan kunci API di perangkat.
///
/// Dibuat sebagai antarmuka supaya bisa diganti versi palsu saat pengujian
/// tanpa menyentuh Android Keystore.
abstract class ApiKeyStore {
  /// Kunci yang tersimpan, atau null bila pengguna belum mengaturnya.
  Future<String?> read();

  /// Menyimpan kunci. String kosong dianggap menghapus.
  Future<void> save(String key);

  /// Menghapus kunci yang tersimpan.
  Future<void> clear();
}

/// Penyimpanan kunci memakai Android Keystore / iOS Keychain.
///
/// Dipilih daripada Firestore karena kunci API tidak boleh ikut terkirim
/// ke server. Penyimpanan ini juga tidak ikut backup cloud.
class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Nama entri di penyimpanan aman.
  static const String storageKey = 'groq_api_key';

  /// Kunci bawaan saat aplikasi dijalankan dengan `--dart-define-from-file`.
  /// Dipakai pengembang; build publik dibuat tanpa nilai ini.
  static const String buildTimeKey = String.fromEnvironment('GROQ_API_KEY');

  @override
  Future<String?> read() async {
    final saved = await _storage.read(key: storageKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();

    // Cadangan untuk pengembangan: kunci dari --dart-define-from-file.
    final fallback = buildTimeKey.trim();
    return fallback.isEmpty ? null : fallback;
  }

  @override
  Future<void> save(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    await _storage.write(key: storageKey, value: trimmed);
  }

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}
