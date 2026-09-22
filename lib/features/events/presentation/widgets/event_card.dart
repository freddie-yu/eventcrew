import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/status_badge.dart';
import '../../data/event_model.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.isMember,
    required this.onTap,
    required this.onJoin,
    this.isJoining = false,
  });

  final EventModel event;
  final bool isMember;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: isMember ? 'Confirmed' : 'Available',
                  tone: isMember ? BadgeTone.positive : BadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.schedule, text: dateFormat.format(event.startsAt)),
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.place_outlined, text: event.location),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: isMember
                  ? OutlinedButton(onPressed: onTap, child: const Text('View Shift'))
                  : ElevatedButton(
                      onPressed: isJoining ? null : onJoin,
                      child: isJoining
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Join Shift'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ),
      ],
    );
  }
}
