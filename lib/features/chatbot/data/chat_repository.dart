import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

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
    this.modelName = 'gemini-1.5-flash',
  });

  final FirebaseAI? firebaseAI;
  final String modelName;

  FirebaseAI _getClient() {
    return firebaseAI ?? FirebaseAI.agentPlatform();
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

      // Konversi riwayat sesi ke Content SDK
      final chatHistory = history.map((h) {
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
    } on SocketException {
      throw const ChatException(
        'Koneksi internet terputus. Mohon periksa sambungan internet Anda dan coba lagi.',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' ||
          e.message?.contains('Vertex AI') == true ||
          e.message?.contains('BILLING') == true) {
        throw const ChatException(
          'Layanan MotoAI di Firebase belum aktif atau memerlukan Blaze Plan. Silakan periksa pengaturan Firebase Vertex AI di konsol.',
        );
      }
      throw ChatException(
        'Layanan MotoAI sedang mengalami gangguan (${e.message ?? e.code}). Silakan coba sesaat lagi.',
      );
    } on FirebaseAIException catch (e) {
      if (e.message.contains('quota') || e.message.contains('429')) {
        throw const ChatException(
          'Batas kuota pertanyaan AI tercapai sementara. Mohon tunggu beberapa saat sebelum bertanya lagi.',
        );
      }
      throw ChatException(
        'Asisten MotoAI tidak dapat memproses pertanyaan: ${e.message}',
      );
    } catch (e) {
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

      throw const ChatException(
        'Terjadi kendala saat menghubungi asisten MotoAI. Silakan coba sesaat lagi.',
      );
    }
  }
}

/// Exception kustom untuk error chatbot dengan pesan ramah pengguna
class ChatException implements Exception {
  const ChatException(this.userFriendlyMessage);

  final String userFriendlyMessage;

  @override
  String toString() => userFriendlyMessage;
}
