import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

    test('Mendukung payload dengan karakter Unicode (bullet •, emotikon) via utf8.encode', () async {
      // Menyiapkan mock request & response
      final fakeRequest = _FakeHttpClientRequest();
      final fakeClient = _FakeHttpClient(fakeRequest);

      final repo = GroqChatRepository(
        apiKey: 'gsk_test_valid_key',
        httpClient: fakeClient,
      );

      final result = await repo.sendMessage(
        systemInstruction: '• Poin analisa motor 🛵',
        history: [],
        userMessage: 'Keluhan tarikan gredek • CVT',
      );

      expect(result, 'Respon aman dari AI');
      // Memastikan request body di-encode sebagai byte utf8 tanpa melempar ArgumentError
      expect(fakeRequest.writtenBytes, isNotEmpty);
    });
  });
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.request);
  final _FakeHttpClientRequest request;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #postUrl) {
      return Future.value(request);
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, Object> _headers = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  final List<int> writtenBytes = [];
  final _FakeHttpHeaders _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  void add(List<int> data) {
    writtenBytes.addAll(data);
  }

  @override
  Future<HttpClientResponse> close() {
    return Future.value(_FakeHttpClientResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final jsonResponse = '{"choices":[{"message":{"content":"Respon aman dari AI"}}]}';
    return Stream.value(utf8.encode(jsonResponse)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
