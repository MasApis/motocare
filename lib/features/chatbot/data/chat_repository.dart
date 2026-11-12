import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/chat_prompt_builder.dart';

/// Abstrak repository untuk komunikasi dengan asisten AI
abstract class ChatRepository {
  /// Mengirim pesan ke AI dengan system instruction tertentu
  /// dan riwayat obrolan dalam sesi saat ini.
  Future<String> sendMessage({
    required String systemInstruction,
    required List<({String role, String text})> history,
    required String userMessage,
  });
}

/// Implementasi ChatRepository menggunakan Groq Cloud API (100% gratis tanpa kartu kredit)
class GroqChatRepository implements ChatRepository {
  GroqChatRepository({
    this.apiKey = const String.fromEnvironment('GROQ_API_KEY'),
    this.modelName = const String.fromEnvironment(
      'GROQ_MODEL',
      defaultValue: 'openai/gpt-oss-120b',
    ),
    this.httpClient,
  });

  final String apiKey;
  final String modelName;
  final HttpClient? httpClient;

  /// Daftar model obrolan teruji dan stabil di Groq (diurutkan dari prioritas terbaik)
  static const List<String> _preferredModels = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'qwen/qwen3.8-27b',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'llama3-70b-8192',
    'llama3-8b-8192',
  ];

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Batas tunggu permintaan; mencegah spinner berputar tanpa akhir
  /// saat Wi-Fi tersambung tetapi tidak ada internet.
  static const Duration _requestTimeout = Duration(seconds: 20);

  @override
  Future<String> sendMessage({
    required String systemInstruction,
    required List<({String role, String text})> history,
    required String userMessage,
    String? overrideModelName,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw const ChatException(
        'Kunci API Groq belum dikonfigurasi. Jalankan aplikasi dengan argumen: --dart-define-from-file=dart_defines.json',
      );
    }

    final effectiveModel = overrideModelName ?? modelName;

    // Pangkas riwayat chat agar hemat token (maksimal 10 pesan terakhir)
    final trimmedHistory = ChatPromptBuilder.trimHistory(history);

    // Bangun pesan format standar OpenAI / Groq
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemInstruction,
      },
      ...trimmedHistory.map((h) => {
            'role': h.role == 'user' ? 'user' : 'assistant',
            'content': h.text,
          }),
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    final requestBody = jsonEncode({
      'model': effectiveModel,
      'messages': messages,
      'temperature': 0.2,
      'max_tokens': 600,
    });

    final client = httpClient ?? HttpClient();
    try {
      final uri = Uri.parse(_endpoint);
      final request = await client.postUrl(uri).timeout(_requestTimeout);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $cleanKey');
      request.add(utf8.encode(requestBody));

      final response = await request.close().timeout(_requestTimeout);
      final responseBody =
          await response.transform(utf8.decoder).join().timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw const ChatException(
            'Tidak ada respon dari asisten MotoAI. Silakan coba ajukan pertanyaan kembali.',
          );
        }
        final firstChoice = choices[0] as Map<String, dynamic>;
        final messageObj = firstChoice['message'] as Map<String, dynamic>?;
        final content = messageObj?['content'] as String?;
        if (content == null || content.trim().isEmpty) {
          throw const ChatException(
            'Tidak ada respon dari asisten MotoAI. Silakan coba ajukan pertanyaan kembali.',
          );
        }
        return content.trim();
      }

      debugPrint('Groq API Error (${response.statusCode}): $responseBody');

      if (response.statusCode == 404) {
        final availableModels = await _fetchAvailableModels(client, cleanKey);
        debugPrint('Groq Available Models: $availableModels');

        // Cari kandidat model yang teruji dan tersedia di akun
        final safeFallback = _preferredModels.firstWhere(
          (m) => availableModels.contains(m) && m != effectiveModel,
          orElse: () => '',
        );

        if (overrideModelName == null && safeFallback.isNotEmpty) {
          debugPrint('Otomatis mencoba model fallback yang aman: $safeFallback');
          return await sendMessage(
            systemInstruction: systemInstruction,
            history: history,
            userMessage: userMessage,
            overrideModelName: safeFallback,
          );
        }
        throw ChatException(
          'Model ($effectiveModel) tidak dapat diakses saat ini. Silakan periksa koneksi dan coba beberapa saat lagi.',
        );
      }

      if (response.statusCode == 401) {
        throw const ChatException(
          'Kunci API Groq tidak valid. Periksa kembali nilai GROQ_API_KEY yang dimasukkan.',
        );
      }
      if (response.statusCode == 429) {
        throw const ChatException(
          'Batas kuota pertanyaan AI tercapai sementara. Mohon tunggu beberapa saat sebelum bertanya lagi.',
        );
      }
      if (response.statusCode >= 500) {
        throw const ChatException(
          'Layanan MotoAI sedang mengalami gangguan sementara. Silakan coba sesaat lagi.',
        );
      }

      throw ChatException(
        'Terjadi kendala pada layanan AI (${response.statusCode}). Silakan coba sesaat lagi.',
      );
    } on SocketException catch (e) {
      debugPrint('Groq SocketException: $e');
      throw const ChatException(
        'Koneksi internet terputus. Mohon periksa sambungan internet Anda dan coba lagi.',
      );
    } on TimeoutException {
      throw const ChatException(
        'Koneksi terlalu lambat atau tidak tersedia. Periksa internet Anda lalu coba lagi.',
      );
    } catch (e) {
      debugPrint('Groq General Error: $e');
      if (e is ChatException) rethrow;

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('failed host lookup')) {
        throw const ChatException(
          'Tidak dapat terhubung ke internet. Periksa koneksi data atau Wi-Fi Anda.',
        );
      }

      throw ChatException(
        'Terjadi kendala saat menghubungi asisten MotoAI ($e).',
      );
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// Mengambil daftar ID model yang aktif dan diizinkan pada akun Groq pengguna
  Future<List<String>> _fetchAvailableModels(
    HttpClient client,
    String cleanKey,
  ) async {
    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/models');
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $cleanKey');
      final response = await request.close().timeout(_requestTimeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null) {
          return list
              .map((e) => (e as Map<String, dynamic>)['id'] as String)
              .where((id) =>
                  !id.contains('whisper') &&
                  !id.contains('guard') &&
                  !id.contains('vision'))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil daftar model Groq: $e');
    }
    return [];
  }
}

/// Exception kustom untuk error chatbot dengan pesan ramah pengguna
class ChatException implements Exception {
  const ChatException(this.userFriendlyMessage);

  final String userFriendlyMessage;

  @override
  String toString() => userFriendlyMessage;
}
