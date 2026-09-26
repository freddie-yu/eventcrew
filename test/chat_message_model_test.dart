import 'package:eventcrew/features/chat/data/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatMessage.fromMap parses staff identity', () {
    final message = ChatMessage.fromMap({
      'id': 'msg-1',
      'event_id': 'event-1',
      'user_id': 'user-1',
      'body': 'On my way!',
      'created_at': '2026-02-01T08:05:00Z',
      'profiles': {
        'full_name': 'Sarah Jones',
        'role': 'Event Staff',
        'avatar_url': null,
      },
    });

    expect(message.id, 'msg-1');
    expect(message.eventId, 'event-1');
    expect(message.body, 'On my way!');
    expect(message.senderName, 'Sarah Jones');
    expect(message.senderRole, 'Event Staff');
  });

  test('ChatMessage falls back when identity is absent', () {
    final message = ChatMessage.fromMap({
      'id': 'msg-2',
      'event_id': 'event-1',
      'user_id': 'user-2',
      'body': 'Here',
      'created_at': '2026-02-01T08:06:00Z',
    });

    expect(message.senderName, 'Crew member');
  });
}
