import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/chatbot/data/chat_repository.dart';

void main() {
  group('GroqChatRepository Unit Tests', () {
    test('Melempar ChatException ramah jika GROQ_API_KEY belum dikonfigurasi', () async {
      final repo = GroqChatRepository(apiKey: '');

      expect(
        () => repo.sendMessage(
          systemInstruction: 'Anda adalah mekanik',
          history: [],
          userMessage: 'Motor saya bunyi aneh',
        ),
        throwsA(
          isA<ChatException>().having(
            (e) => e.userFriendlyMessage,
            'userFriendlyMessage',
            contains('Kunci API Groq belum dikonfigurasi'),
          ),
        ),
      );
    });

    test('Melempar ChatException jika API key hanya berisi spasi kosong', () async {
      final repo = GroqChatRepository(apiKey: '   ');

      expect(
        () => repo.sendMessage(
          systemInstruction: 'Anda adalah mekanik',
          history: [],
          userMessage: 'Motor saya bunyi aneh',
        ),
        throwsA(
          isA<ChatException>().having(
            (e) => e.userFriendlyMessage,
            'userFriendlyMessage',
            contains('--dart-define=GROQ_API_KEY'),
          ),
        ),
      );
    });
  });
}
