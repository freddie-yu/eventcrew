import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../attendance/presentation/widgets/attendance_panel.dart';
import '../data/event_model.dart';
import 'events_providers.dart';
import 'widgets/capacity_indicator.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final leaveState = ref.watch(leaveEventControllerProvider);
    final joinState = ref.watch(joinEventControllerProvider);

    ref.listen(leaveEventControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(next.error!))),
        );
      }
    });
    ref.listen(joinEventControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(next.error!))),
        );
      }
    });

    Future<void> joinShift(EventModel event) async {
      final status =
          await ref.read(joinEventControllerProvider.notifier).join(event.id);
      if (status != null && context.mounted) {
        final text = status == MembershipStatus.waitlisted
            ? 'Added to the waitlist.'
            : 'Shift confirmed.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      }
    }

    Future<void> leaveShift() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Leave this shift?'),
          content: const Text(
            'If you are confirmed, the next waitlisted staff member may be '
            'promoted automatically. Clock out before leaving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep shift'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Leave shift'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      final success =
          await ref.read(leaveEventControllerProvider.notifier).leave(eventId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift removed from My shifts.')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shift Detail')),
      body: AsyncValueView(
        value: eventAsync,
        onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
        data: (event) => AsyncValueView(
          value: membershipsAsync,
          onRetry: () => ref.invalidate(myMembershipsProvider),
          data: (memberships) {
            final membership = memberships[event.id];
            final isMember = membership != null;
            final dateFormat = DateFormat('EEE, MMM d, yyyy');
            final timeFormat = DateFormat('h:mm a');

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (membership != null)
                      StatusBadge(
                        label: membership == MembershipStatus.waitlisted
                            ? 'Waitlisted'
                            : 'Confirmed',
                        tone: membership == MembershipStatus.waitlisted
                            ? BadgeTone.warning
                            : BadgeTone.positive,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  text: dateFormat.format(event.startsAt),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.schedule,
                  text:
                      '${timeFormat.format(event.startsAt)} – ${timeFormat.format(event.endsAt)}',
                ),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.place_outlined, text: event.location),
                if (event.description != null &&
                    event.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    event.description!,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
                if (event.capacity > 0) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: CapacityIndicator(event: event),
                  ),
                ],
                const SizedBox(height: 24),
                if (!isMember)
                  ElevatedButton(
                    onPressed: joinState.isLoading ? null : () => joinShift(event),
                    child: Text(
                      joinState.isLoading
                          ? 'Joining…'
                          : event.isFull
                              ? 'Join Waitlist'
                              : 'Join Shift',
                    ),
                  )
                else if (membership == MembershipStatus.waitlisted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Text(
                      'You are on the waitlist. You will be promoted '
                      'automatically if a confirmed place opens.',
                      style: TextStyle(color: AppTheme.warning),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: leaveState.isLoading ? null : leaveShift,
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Leave Waitlist'),
                  ),
                ] else ...[
                  AttendancePanel(eventId: event.id),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/events/${event.id}/chat'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Open Team Chat'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: leaveState.isLoading ? null : leaveShift,
                    icon: const Icon(Icons.event_busy_outlined),
                    label: Text(
                      leaveState.isLoading ? 'Leaving…' : 'Leave Shift',
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
