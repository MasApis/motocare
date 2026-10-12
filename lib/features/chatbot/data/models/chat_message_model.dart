/// Status pengiriman pesan chat
enum ChatMessageStatus {
  sending,
  sent,
  error,
}

/// Model pesan dalam sesi Chatbot Diagnosa (F7)
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.status = ChatMessageStatus.sent,
    this.errorMessage,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageStatus status;
  final String? errorMessage;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    ChatMessageStatus? status,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
