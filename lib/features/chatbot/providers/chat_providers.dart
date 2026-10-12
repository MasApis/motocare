import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/chat_prompt_builder.dart';
import '../../../core/vehicle_components.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_message_model.dart';

/// Provider instance repository chatbot (default menggunakan Groq API)
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return GroqChatRepository();
});

/// State untuk sesi obrolan chatbot
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.validationError,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? validationError;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
    );
  }
}

/// Notifier pengelola riwayat pesan sesi memori chatbot (F7)
class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return const ChatState();
  }

  /// Membersihkan riwayat chat sesi ini
  void clearHistory() {
    state = const ChatState();
  }

  /// Mengirim pertanyaan pengguna ke AI
  Future<void> sendMessage(String text) async {
    final validation = ChatPromptBuilder.validateUserMessage(text);
    if (validation != null) {
      state = state.copyWith(validationError: validation);
      return;
    }

    final trimmedText = text.trim();
    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    final userMessage = ChatMessage(
      id: userMessageId,
      text: trimmedText,
      isUser: true,
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sent,
    );

    // Tambahkan pesan user ke antrian chat
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearValidationError: true,
    );

    try {
      // Dapatkan konteks motor aktif saat ini
      final activeVehicle = ref.read(selectedVehicleProvider);
      final vehicleName = activeVehicle?.name ?? 'Motor Saya';
      final brand = activeVehicle?.brand ?? 'Motor';
      final model = activeVehicle?.model ?? 'Matic';
      final currentKm = activeVehicle?.currentKm ?? 0;

      // Dapatkan data komponen motor aktif bila ada
      List<ComponentContextSummary> componentSummaries = [];
      if (activeVehicle != null) {
        final components =
            ref.read(vehicleComponentsStreamProvider(activeVehicle.id)).asData?.value ?? [];

        componentSummaries = ComponentType.values.map((type) {
          final comp = components.where((c) => c.type == type).firstOrNull;
          return ComponentContextSummary.fromKm(
            type: type,
            intervalKm: comp?.intervalKm ?? DefaultIntervals.forType(type),
            lastServiceKm: comp?.lastServiceKm ?? currentKm,
            currentKm: currentKm,
          );
        }).toList();
      }

      final systemInstruction = ChatPromptBuilder.buildSystemInstruction(
        vehicleName: vehicleName,
        brand: brand,
        model: model,
        currentKm: currentKm,
        components: componentSummaries,
      );

      // Siapkan riwayat obrolan dalam sesi untuk konteks Gemini (dibatasi 10 terakhir untuk hemat kuota)
      final rawHistory = state.messages
          .where((m) => m.id != userMessageId && m.status == ChatMessageStatus.sent)
          .map((m) => (role: m.isUser ? 'user' : 'model', text: m.text))
          .toList();
      final history = ChatPromptBuilder.trimHistory(rawHistory);

      final chatRepo = ref.read(chatRepositoryProvider);
      final responseText = await chatRepo.sendMessage(
        systemInstruction: systemInstruction,
        history: history,
        userMessage: trimmedText,
      );

      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: ChatPromptBuilder.cleanResponseText(responseText),
        isUser: false,
        timestamp: DateTime.now(),
        status: ChatMessageStatus.sent,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } on ChatException catch (e) {
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: e.userFriendlyMessage,
        isUser: false,
        timestamp: DateTime.now(),
        status: ChatMessageStatus.error,
        errorMessage: e.userFriendlyMessage,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    } catch (_) {
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text:
            'Terjadi kendala saat menghubungi asisten MotoAI. Silakan periksa koneksi internet Anda dan coba lagi.',
        isUser: false,
        timestamp: DateTime.now(),
        status: ChatMessageStatus.error,
        errorMessage: 'Gagal memproses pesan.',
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }
}

/// Provider state obrolan chatbot
final chatNotifierProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
