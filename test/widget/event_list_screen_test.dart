import 'package:eventcrew/features/events/data/event_model.dart';
import 'package:eventcrew/features/events/presentation/event_list_screen.dart';
import 'package:eventcrew/features/events/presentation/events_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an empty state when there are no upcoming events',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upcomingEventsProvider.overrideWith(
            (ref) async => const <EventModel>[],
          ),
          myMembershipsProvider.overrideWith(
            (ref) async => const <String, MembershipStatus>{},
          ),
        ],
        child: const MaterialApp(home: EventListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No upcoming events'), findsOneWidget);
  });

  testWidgets('shows Join Shift and Available for an open event',
      (tester) async {
    final event = EventModel(
      id: 'event-1',
      title: 'Riverside Festival',
      description: null,
      location: 'Riverside Park',
      startsAt: DateTime(2026, 2, 1, 8),
      endsAt: DateTime(2026, 2, 1, 16),
      capacity: 12,
      confirmedCount: 9,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upcomingEventsProvider.overrideWith((ref) async => [event]),
          myMembershipsProvider.overrideWith(
            (ref) async => const <String, MembershipStatus>{},
          ),
        ],
        child: const MaterialApp(home: EventListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Riverside Festival'), findsOneWidget);
    expect(find.text('Join Shift'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('9 of 12 staffed'), findsOneWidget);
  });

  testWidgets('shows confirmed membership', (tester) async {
    final event = EventModel(
      id: 'event-1',
      title: 'Riverside Festival',
      description: null,
      location: 'Riverside Park',
      startsAt: DateTime(2026, 2, 1, 8),
      endsAt: DateTime(2026, 2, 1, 16),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upcomingEventsProvider.overrideWith((ref) async => [event]),
          myMembershipsProvider.overrideWith(
            (ref) async => const {
              'event-1': MembershipStatus.confirmed,
            },
          ),
        ],
        child: const MaterialApp(home: EventListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('View Shift'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });

  testWidgets('shows waitlist action when shift is full', (tester) async {
    final event = EventModel(
      id: 'event-1',
      title: 'Riverside Festival',
      description: null,
      location: 'Riverside Park',
      startsAt: DateTime(2026, 2, 1, 8),
      endsAt: DateTime(2026, 2, 1, 16),
      capacity: 12,
      confirmedCount: 12,
      waitlistedCount: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upcomingEventsProvider.overrideWith((ref) async => [event]),
          myMembershipsProvider.overrideWith(
            (ref) async => const <String, MembershipStatus>{},
          ),
        ],
        child: const MaterialApp(home: EventListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Join Waitlist'), findsOneWidget);
    expect(find.text('2 waiting'), findsOneWidget);
  });
}
