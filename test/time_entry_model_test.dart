import 'package:eventcrew/features/attendance/data/time_entry_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeEntry', () {
    test('an entry with clock_out null is active', () {
      final entry = TimeEntry.fromMap({
        'id': 'entry-1',
        'event_id': 'event-1',
        'user_id': 'user-1',
        'clock_in': '2026-01-10T09:00:00Z',
        'clock_out': null,
      });

      expect(entry.isActive, isTrue);
      expect(entry.clockOut, isNull);
    });

    test('an entry with clock_out set is not active', () {
      final entry = TimeEntry.fromMap({
        'id': 'entry-1',
        'event_id': 'event-1',
        'user_id': 'user-1',
        'clock_in': '2026-01-10T09:00:00Z',
        'clock_out': '2026-01-10T17:00:00Z',
      });

      expect(entry.isActive, isFalse);
      expect(entry.clockOut, isNotNull);
      expect(entry.clockOut!.isAfter(entry.clockIn), isTrue);
    });

    test('clocking out transitions an active entry to inactive', () {
      final active = TimeEntry(
        id: 'entry-1',
        eventId: 'event-1',
        userId: 'user-1',
        clockIn: DateTime.utc(2026, 1, 10, 9),
      );
      expect(active.isActive, isTrue);

      final closed = TimeEntry(
        id: active.id,
        eventId: active.eventId,
        userId: active.userId,
        clockIn: active.clockIn,
        clockOut: DateTime.utc(2026, 1, 10, 17),
      );
      expect(closed.isActive, isFalse);
    });
  });
}
