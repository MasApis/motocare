import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/chat_prompt_builder.dart';

/// Abstrak repository untuk komunikasi dengan Gemini AI
abstract class ChatRepository {
  /// Mengirim pesan ke AI dengan system instruction tertentu
  /// dan riwayat obrolan dalam sesi saat ini.
  Future<String> sendMessage({
    required String systemInstruction,
    required List<({String role, String text})> history,
    required String userMessage,
  });
}

/// Implementasi ChatRepository menggunakan Firebase AI SDK
class FirebaseAIChatRepository implements ChatRepository {
  FirebaseAIChatRepository({
    this.firebaseAI,
    this.modelName = 'gemini-3.8-flash',
  });

  final FirebaseAI? firebaseAI;
  final String modelName;

  FirebaseAI _getClient() {
    return firebaseAI ?? FirebaseAI.googleAI();
  }

  @override
  Future<String> sendMessage({
    required String systemInstruction,
    required List<({String role, String text})> history,
    required String userMessage,
  }) async {
    try {
      final client = _getClient();
      final model = client.generativeModel(
        model: modelName,
        systemInstruction: Content.system(systemInstruction),
      );

      // Pangkas riwayat chat agar tidak melebihi batas pesan terakhir (hemat kuota)
      final trimmedHistory = ChatPromptBuilder.trimHistory(history);

      // Konversi riwayat sesi ke Content SDK
      final chatHistory = trimmedHistory.map((h) {
        if (h.role == 'user') {
          return Content.text(h.text);
        } else {
          return Content.model([TextPart(h.text)]);
        }
      }).toList();

      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content.text(userMessage));

      final responseText = response.text?.trim();
      if (responseText == null || responseText.isEmpty) {
        throw const ChatException(
          'Tidak ada jawaban dari asisten AI. Silakan coba ajukan pertanyaan dengan kalimat berbeda.',
        );
      }

      return responseText;
    } on SocketException catch (e) {
      debugPrint('MotoAI SocketException: $e');
      throw const ChatException(
        'Koneksi internet terputus. Mohon periksa sambungan internet Anda dan coba lagi.',
      );
    } on FirebaseException catch (e) {
      debugPrint('MotoAI FirebaseException: ${e.code} - ${e.message}');
      if (e.code == 'app-check-failed' ||
          e.message?.toLowerCase().contains('app check') == true ||
          e.message?.toLowerCase().contains('appcheck') == true ||
          e.message?.toLowerCase().contains('attestation') == true) {
        throw const ChatException(
          'Keamanan aplikasi (App Check) gagal diverifikasi. Pastikan debug token telah terdaftar di konsol Firebase.',
        );
      }
      if (e.code == 'permission-denied') {
        throw const ChatException(
          'Akses layanan AI ditolak. Pastikan Firebase AI Logic telah diaktifkan dan App Check terverifikasi.',
        );
      }
      throw ChatException(
        'Layanan MotoAI sedang mengalami gangguan (${e.message ?? e.code}). Silakan coba sesaat lagi.',
      );
    } on ServiceApiNotEnabled catch (e) {
      debugPrint('MotoAI ServiceApiNotEnabled: $e');
      throw const ChatException(
        'Layanan Firebase AI Logic belum aktif di konsol. Buka Firebase Console -> AI Logic, lalu klik "Get started".',
      );
    } on InvalidApiKey catch (e) {
      debugPrint('MotoAI InvalidApiKey: $e');
      throw const ChatException(
        'Kunci konfigurasi Firebase tidak valid. Pastikan google-services.json sesuai.',
      );
    } on FirebaseAIException catch (e) {
      debugPrint('MotoAI FirebaseAIException: $e');
      final msg = e.message.toLowerCase();
      if (msg.contains('quota') ||
          msg.contains('429') ||
          msg.contains('resource_exhausted') ||
          msg.contains('rate limit')) {
        throw const ChatException(
          'Batas kuota pertanyaan AI tercapai sementara. Mohon tunggu beberapa saat sebelum bertanya lagi.',
        );
      }
      if (msg.contains('app check') ||
          msg.contains('appcheck') ||
          msg.contains('attestation') ||
          msg.contains('403')) {
        throw const ChatException(
          'Keamanan aplikasi (App Check) gagal diverifikasi. Pastikan debug token telah terdaftar di konsol Firebase.',
        );
      }
      if (msg.contains('not found') || msg.contains('404')) {
        throw ChatException(
          'Model AI tidak ditemukan (${e.message}).',
        );
      }
      throw ChatException(
        'Asisten MotoAI sedang tidak dapat merespons saat ini (${e.message}).',
      );
    } catch (e) {
      debugPrint('MotoAI General Error: $e');
      if (e is ChatException) rethrow;

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection')) {
        throw const ChatException(
          'Tidak dapat terhubung ke internet. Periksa koneksi data atau Wi-Fi Anda.',
        );
      }
      if (errorStr.contains('quota') ||
          errorStr.contains('429') ||
          errorStr.contains('rate limit')) {
        throw const ChatException(
          'Batas kuota pertanyaan AI tercapai sementara. Mohon tunggu beberapa saat sebelum bertanya lagi.',
        );
      }
      if (errorStr.contains('app check') ||
          errorStr.contains('appcheck') ||
          errorStr.contains('attestation')) {
        throw const ChatException(
          'Keamanan aplikasi (App Check) gagal diverifikasi. Pastikan debug token telah terdaftar di konsol Firebase.',
        );
      }

      throw ChatException(
        'Terjadi kendala saat menghubungi asisten MotoAI ($e).',
      );
    }
  }
}

/// Implementasi ChatRepository menggunakan Groq Cloud API (100% gratis tanpa kartu kredit)
class GroqChatRepository implements ChatRepository {
  GroqChatRepository({
    this.apiKey = const String.fromEnvironment('GROQ_API_KEY'),
    this.modelName = 'llama-3.1-8b-instant',
    this.httpClient,
  });

  final String apiKey;
  final String modelName;
  final HttpClient? httpClient;

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

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
        'Kunci API Groq belum dikonfigurasi. Jalankan aplikasi dengan argumen: --dart-define=GROQ_API_KEY=gsk_...',
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
      'temperature': 0.7,
      'max_tokens': 1024,
    });

    final client = httpClient ?? HttpClient();
    try {
      final uri = Uri.parse(_endpoint);
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $cleanKey');
      request.write(requestBody);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

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
        if (overrideModelName == null &&
            availableModels.isNotEmpty &&
            !availableModels.contains(modelName)) {
          final fallbackModel = availableModels.first;
          debugPrint('Otomatis mencoba model fallback: $fallbackModel');
          return await sendMessage(
            systemInstruction: systemInstruction,
            history: history,
            userMessage: userMessage,
            overrideModelName: fallbackModel,
          );
        }
        throw ChatException(
          'Model ($effectiveModel) tidak ditemukan. Model yang tersedia di akun Groq Anda: ${availableModels.join(', ')}',
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
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $cleanKey');
      final response = await request.close();
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
