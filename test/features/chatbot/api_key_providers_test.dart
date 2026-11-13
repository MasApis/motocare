import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/chatbot/data/api_key_store.dart';
import 'package:motocare/features/chatbot/providers/api_key_providers.dart';

/// Penyimpanan kunci palsu di memori.
class FakeApiKeyStore implements ApiKeyStore {
  FakeApiKeyStore([this.value]);

  String? value;
  bool failRead = false;

  @override
  Future<String?> read() async {
    if (failRead) throw Exception('penyimpanan rusak');
    return value;
  }

  @override
  Future<void> save(String key) async => value = key;

  @override
  Future<void> clear() async => value = null;
}

void main() {
  ProviderContainer containerWith(ApiKeyStore store) {
    final container = ProviderContainer(
      overrides: [apiKeyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Menunggu pembacaan awal selesai (dijalankan sebagai Future di build).
  Future<ApiKeyState> settled(ProviderContainer container) async {
    for (var i = 0;
        i < 20 && container.read(apiKeyProvider).status == ApiKeyStatus.checking;
        i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(apiKeyProvider);
  }

  group('ApiKeyNotifier', () {
    test('missing saat belum ada kunci tersimpan', () async {
      final container = containerWith(FakeApiKeyStore());

      final state = await settled(container);

      expect(state.status, ApiKeyStatus.missing);
      expect(state.isReady, isFalse);
    });

    test('ready saat kunci sudah tersimpan', () async {
      final container = containerWith(FakeApiKeyStore('gsk_tersimpan'));

      final state = await settled(container);

      expect(state.status, ApiKeyStatus.ready);
      expect(state.key, 'gsk_tersimpan');
      expect(state.isReady, isTrue);
    });

    test('save menyimpan kunci dan mengubah status jadi ready', () async {
      final store = FakeApiKeyStore();
      final container = containerWith(store);
      await settled(container);

      await container.read(apiKeyProvider.notifier).save('  gsk_baru  ');

      expect(store.value, 'gsk_baru');
      expect(container.read(apiKeyProvider).key, 'gsk_baru');
      expect(container.read(apiKeyProvider).isReady, isTrue);
    });

    test('save dengan teks kosong sama dengan menghapus', () async {
      final store = FakeApiKeyStore('gsk_lama');
      final container = containerWith(store);
      await settled(container);

      await container.read(apiKeyProvider.notifier).save('   ');

      expect(store.value, isNull);
      expect(container.read(apiKeyProvider).status, ApiKeyStatus.missing);
    });

    test('clear menghapus kunci tersimpan', () async {
      final store = FakeApiKeyStore('gsk_lama');
      final container = containerWith(store);
      await settled(container);

      await container.read(apiKeyProvider.notifier).clear();

      expect(store.value, isNull);
      expect(container.read(apiKeyProvider).status, ApiKeyStatus.missing);
    });

    test('penyimpanan gagal dibaca dianggap belum diatur', () async {
      final container = containerWith(FakeApiKeyStore()..failRead = true);

      final state = await settled(container);

      expect(state.status, ApiKeyStatus.missing);
    });
  });
}
