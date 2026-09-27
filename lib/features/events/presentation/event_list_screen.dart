import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/push_providers.dart';
import '../data/event_model.dart';
import 'events_providers.dart';
import 'widgets/event_card.dart';

class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final mutatingEventId = ref.watch(membershipMutationEventIdProvider);
    final pushRegistration = ref.watch(pushRegistrationControllerProvider);
    final pushEnabled = pushRegistration.valueOrNull ?? false;

    ref.listen(joinEventControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(next.error!))),
        );
      }
    });

    ref.listen(foregroundPushMessageProvider, (previous, next) {
      next.whenData((message) {
        final title = message.notification?.title ?? 'EventCrew update';
        final body = message.notification?.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body == null || body.isEmpty ? title : '$title — $body'),
          ),
        );
      });
    });

    Future<void> refresh() async {
      ref.invalidate(upcomingEventsProvider);
      ref.invalidate(myMembershipsProvider);
      await ref.read(upcomingEventsProvider.future);
    }

    Future<void> enableNotifications() async {
      final enabled =
          await ref.read(pushRegistrationControllerProvider.notifier).enable();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Shift notifications enabled.'
                : 'Notifications were not enabled. Check your browser permission settings and try again.',
          ),
        ),
      );
    }

    Future<void> handleJoin(String eventId) async {
      ref.read(membershipMutationEventIdProvider.notifier).state = eventId;
      final status =
          await ref.read(joinEventControllerProvider.notifier).join(eventId);
      ref.read(membershipMutationEventIdProvider.notifier).state = null;
      if (status != null && context.mounted) {
        final message = status == MembershipStatus.waitlisted
            ? 'Shift is full — you joined the waitlist.'
            : 'Shift confirmed.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        context.push('/events/$eventId');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Shifts'),
        actions: [
          if (Env.isFirebaseConfigured)
            IconButton(
              tooltip:
                  pushEnabled ? 'Notifications enabled' : 'Enable notifications',
              icon: Icon(
                pushEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
              ),
              onPressed:
                  pushEnabled || pushRegistration.isLoading
                      ? null
                      : enableNotifications,
            ),
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
            data: (memberships) {
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

              final myShifts = events
                  .where((event) => memberships.containsKey(event.id))
                  .toList();
              final available = events
                  .where((event) => !memberships.containsKey(event.id))
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (Env.isFirebaseConfigured && !pushEnabled) ...[
                    _NotificationPrompt(
                      isLoading: pushRegistration.isLoading,
                      onEnable: enableNotifications,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (myShifts.isNotEmpty) ...[
                    const _SectionHeader(
                      title: 'My shifts',
                      subtitle: 'Confirmed & waitlisted',
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < myShifts.length; i++) ...[
                      EventCard(
                        event: myShifts[i],
                        isMember: true,
                        membershipStatus: memberships[myShifts[i].id],
                        isJoining: false,
                        onTap: () =>
                            context.push('/events/${myShifts[i].id}'),
                        onJoin: () {},
                      ),
                      if (i != myShifts.length - 1)
                        const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                  ],
                  const _SectionHeader(
                    title: 'Available shifts',
                    subtitle: 'Open roles & waitlists',
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
                        onTap: () =>
                            context.push('/events/${available[i].id}'),
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

class _NotificationPrompt extends StatelessWidget {
  const _NotificationPrompt({
    required this.isLoading,
    required this.onEnable,
  });

  final bool isLoading;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stay ahead of shift changes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable notifications for schedule changes, waitlist promotions, and urgent event updates.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isLoading ? null : onEnable,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.notifications_none_outlined),
            label: Text(isLoading ? 'Enabling…' : 'Enable notifications'),
          ),
        ],
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
