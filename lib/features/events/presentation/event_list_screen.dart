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
    final mutatingEventId = ref.watch(membershipMutationEventIdProvider);

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
      ref.read(membershipMutationEventIdProvider.notifier).state = eventId;
      final success =
          await ref.read(joinEventControllerProvider.notifier).join(eventId);
      ref.read(membershipMutationEventIdProvider.notifier).state = null;
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
          data: (events) => AsyncValueView(
            value: membershipsAsync,
            onRetry: () => ref.invalidate(myMembershipsProvider),
            data: (memberIds) {
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

              final myShifts =
                  events.where((event) => memberIds.contains(event.id)).toList();
              final available = events
                  .where((event) => !memberIds.contains(event.id))
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (myShifts.isNotEmpty) ...[
                    const _SectionHeader(
                      title: 'My shifts',
                      subtitle: 'Confirmed assignments',
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < myShifts.length; i++) ...[
                      EventCard(
                        event: myShifts[i],
                        isMember: true,
                        isJoining: false,
                        onTap: () => context.push('/events/${myShifts[i].id}'),
                        onJoin: () {},
                      ),
                      if (i != myShifts.length - 1)
                        const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                  ],
                  const _SectionHeader(
                    title: 'Available shifts',
                    subtitle: 'Open events you can join',
                  ),
                  const SizedBox(height: 10),
                  if (available.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        icon: Icons.task_alt_outlined,
                        title: 'No open shifts',
                        message: 'You have joined every upcoming event.',
                      ),
                    )
                  else
                    for (var i = 0; i < available.length; i++) ...[
                      EventCard(
                        event: available[i],
                        isMember: false,
                        isJoining: mutatingEventId == available[i].id,
                        onTap: () => context.push('/events/${available[i].id}'),
                        onJoin: () => handleJoin(available[i].id),
                      ),
                      if (i != available.length - 1)
                        const SizedBox(height: 12),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }
}
