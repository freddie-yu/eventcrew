import 'package:eventcrew/features/events/data/event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EventModel.fromMap parses required fields', () {
    final event = EventModel.fromMap({
      'id': 'event-1',
      'title': 'Riverside Festival',
      'description': null,
      'location': 'Riverside Park',
      'starts_at': '2026-02-01T08:00:00Z',
      'ends_at': '2026-02-01T16:00:00Z',
    });

    expect(event.id, 'event-1');
    expect(event.title, 'Riverside Festival');
    expect(event.description, isNull);
    expect(event.endsAt.isAfter(event.startsAt), isTrue);
  });
}
