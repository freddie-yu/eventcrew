class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.senderName = 'Crew member',
    this.senderRole,
    this.avatarUrl,
  });

  final String id;
  final String eventId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String senderName;
  final String? senderRole;
  final String? avatarUrl;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final rawProfile = map['profiles'];
    final profile = rawProfile is Map
        ? Map<String, dynamic>.from(rawProfile)
        : const <String, dynamic>{};

    return ChatMessage(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      userId: map['user_id'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      senderName: (profile['full_name'] as String?)?.trim().isNotEmpty == true
          ? profile['full_name'] as String
          : 'Crew member',
      senderRole: profile['role'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }
}
