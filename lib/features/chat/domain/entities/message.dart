enum MessageRole { user, assistant }

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? conversationId;

  const Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.conversationId,
  });
}
