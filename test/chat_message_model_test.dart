import 'package:eventcrew/features/chat/data/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatMessage.fromMap parses a row', () {
    final message = ChatMessage.fromMap({
      'id': 'msg-1',
      'event_id': 'event-1',
      'user_id': 'user-1',
      'body': 'On my way!',
      'created_at': '2026-02-01T08:05:00Z',
    });

    expect(message.id, 'msg-1');
    expect(message.eventId, 'event-1');
    expect(message.body, 'On my way!');
  });
}
