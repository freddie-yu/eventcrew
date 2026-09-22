import 'package:eventcrew/features/attendance/data/time_entry_model.dart';
import 'package:eventcrew/features/attendance/presentation/attendance_providers.dart';
import 'package:eventcrew/features/attendance/presentation/widgets/attendance_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Clock In when there is no active entry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTimeEntryProvider.overrideWith((ref, eventId) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AttendancePanel(eventId: 'event-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Clock In'), findsOneWidget);
    expect(find.text('Not Clocked In'), findsOneWidget);
  });

  testWidgets('shows Clock Out and Clocked In when there is an active entry',
      (tester) async {
    final activeEntry = TimeEntry(
      id: 'entry-1',
      eventId: 'event-1',
      userId: 'user-1',
      clockIn: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTimeEntryProvider.overrideWith((ref, eventId) async => activeEntry),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AttendancePanel(eventId: 'event-1')),
        ),
      ),
    );

    // Deliberately not pumpAndSettle(): once an active entry resolves,
    // the panel starts a real Timer.periodic to tick the elapsed-time
    // display, which keeps scheduling frames and could make
    // pumpAndSettle hang waiting for things to go quiet. Two bounded
    // pumps are enough for the FutureProvider to resolve and the widget
    // to rebuild with the active state.
    await tester.pump();
    await tester.pump();

    expect(find.text('Clock Out'), findsOneWidget);
    expect(find.text('Clocked In'), findsOneWidget);
  });
}
