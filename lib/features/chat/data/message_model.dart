class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      userId: map['user_id'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
