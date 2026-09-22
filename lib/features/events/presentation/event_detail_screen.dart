import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../attendance/presentation/widgets/attendance_panel.dart';
import 'events_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final membershipsAsync = ref.watch(myMembershipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shift Detail')),
      body: AsyncValueView(
        value: eventAsync,
        onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
        data: (event) => AsyncValueView(
          value: membershipsAsync,
          onRetry: () => ref.invalidate(myMembershipsProvider),
          data: (memberIds) {
            final isMember = memberIds.contains(event.id);
            final dateFormat = DateFormat('EEE, MMM d, yyyy');
            final timeFormat = DateFormat('h:mm a');

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
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
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 24),
                if (!isMember)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Join this shift from the events list to clock in and chat with the team.',
                      style: TextStyle(color: Color(0xFF9A3412)),
                    ),
                  )
                else ...[
                  AttendancePanel(eventId: event.id),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/events/${event.id}/chat'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Open Team Chat'),
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
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
