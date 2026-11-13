import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_key_store.dart';

/// Keadaan kunci API Groq di perangkat.
enum ApiKeyStatus {
  /// Sedang dibaca dari penyimpanan.
  checking,

  /// Belum diatur pengguna; Chat AI belum bisa dipakai.
  missing,

  /// Sudah ada dan bisa dipakai.
  ready,
}

/// Status kunci API saat ini.
class ApiKeyState {
  const ApiKeyState({required this.status, this.key});

  final ApiKeyStatus status;
  final String? key;

  bool get isReady => status == ApiKeyStatus.ready && (key?.isNotEmpty ?? false);
}

/// Penyimpanan kunci. Diganti versi palsu saat pengujian.
final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => SecureApiKeyStore());

/// Membaca dan menyimpan kunci API milik pengguna.
class ApiKeyNotifier extends Notifier<ApiKeyState> {
  @override
  ApiKeyState build() {
    unawaited(_load());
    return const ApiKeyState(status: ApiKeyStatus.checking);
  }

  Future<void> _load() async {
    String? saved;
    try {
      saved = await ref.read(apiKeyStoreProvider).read();
    } catch (_) {
      // Gagal baca penyimpanan aman diperlakukan seperti belum diatur.
      saved = null;
    }
    if (!ref.mounted) return;
    state = saved == null || saved.trim().isEmpty
        ? const ApiKeyState(status: ApiKeyStatus.missing)
        : ApiKeyState(status: ApiKeyStatus.ready, key: saved.trim());
  }

  /// Menyimpan kunci baru lalu memperbarui status.
  Future<void> save(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    await ref.read(apiKeyStoreProvider).save(trimmed);
    if (!ref.mounted) return;
    state = ApiKeyState(status: ApiKeyStatus.ready, key: trimmed);
  }

  /// Menghapus kunci tersimpan.
  Future<void> clear() async {
    await ref.read(apiKeyStoreProvider).clear();
    if (!ref.mounted) return;
    state = const ApiKeyState(status: ApiKeyStatus.missing);
  }
}

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, ApiKeyState>(
  ApiKeyNotifier.new,
);
