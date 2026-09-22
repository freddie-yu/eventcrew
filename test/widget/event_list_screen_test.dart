import 'package:eventcrew/features/events/data/event_model.dart';
import 'package:eventcrew/features/events/presentation/event_list_screen.dart';
import 'package:eventcrew/features/events/presentation/events_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an empty state when there are no upcoming events', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upcomingEventsProvider.overrideWith((ref) async => const <EventModel>[]),
          myMembershipsProvider.overrideWith((ref) async => const <String>{}),
        ],
        child: const MaterialApp(home: EventListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No upcoming events'), findsOneWidget);
  });

  testWidgets('shows Join Shift and Available for events the user has not joined',
      (tester) async {
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
          myMembershipsProvider.overrideWith((ref) async => const <String>{}),
        ],
        child: const MaterialApp(home: EventListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Riverside Festival'), findsOneWidget);
    expect(find.text('Join Shift'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
  });

  testWidgets('shows View Shift and Confirmed for events the user has joined',
      (tester) async {
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
          myMembershipsProvider.overrideWith((ref) async => {'event-1'}),
        ],
        child: const MaterialApp(home: EventListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('View Shift'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });
}
