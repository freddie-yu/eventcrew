import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import 'events_providers.dart';
import 'widgets/event_card.dart';

class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final joiningEventId = ref.watch(joiningEventIdProvider);

    ref.listen(joinEventControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(next.error!))),
        );
      }
    });

    Future<void> refresh() async {
      ref.invalidate(upcomingEventsProvider);
      ref.invalidate(myMembershipsProvider);
      await ref.read(upcomingEventsProvider.future);
    }

    Future<void> handleJoin(String eventId) async {
      ref.read(joiningEventIdProvider.notifier).state = eventId;
      final success =
          await ref.read(joinEventControllerProvider.notifier).join(eventId);
      ref.read(joiningEventIdProvider.notifier).state = null;
      if (success && context.mounted) {
        context.push('/events/$eventId');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: AsyncValueView(
          value: eventsAsync,
          onRetry: () => ref.invalidate(upcomingEventsProvider),
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'No upcoming events',
                    message: 'Check back later for new shifts.',
                  ),
                ],
              );
            }

            final memberIds = membershipsAsync.valueOrNull ?? <String>{};

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                final isMember = memberIds.contains(event.id);
                return EventCard(
                  event: event,
                  isMember: isMember,
                  isJoining: joiningEventId == event.id,
                  onTap: () => context.push('/events/${event.id}'),
                  onJoin: () => handleJoin(event.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
