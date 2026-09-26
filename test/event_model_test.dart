import 'package:eventcrew/features/events/data/event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EventModel.fromMap parses staffing fields', () {
    final event = EventModel.fromMap({
      'id': 'event-1',
      'title': 'Riverside Festival',
      'description': null,
      'location': 'Riverside Park',
      'starts_at': '2026-02-01T08:00:00Z',
      'ends_at': '2026-02-01T16:00:00Z',
      'capacity': 12,
      'confirmed_count': 9,
      'waitlisted_count': 2,
    });

    expect(event.id, 'event-1');
    expect(event.title, 'Riverside Festival');
    expect(event.capacity, 12);
    expect(event.confirmedCount, 9);
    expect(event.waitlistedCount, 2);
    expect(event.spotsRemaining, 3);
    expect(event.fillRatio, 0.75);
    expect(event.isFull, isFalse);
  });

  test('MembershipStatus maps database values', () {
    expect(
      MembershipStatus.fromDatabase('waitlisted'),
      MembershipStatus.waitlisted,
    );
    expect(
      MembershipStatus.fromDatabase('confirmed'),
      MembershipStatus.confirmed,
    );
  });
}
