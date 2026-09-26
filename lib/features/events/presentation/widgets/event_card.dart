import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/event_model.dart';
import 'capacity_indicator.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.isMember,
    required this.onTap,
    required this.onJoin,
    this.isJoining = false,
    this.membershipStatus,
  });

  final EventModel event;
  final bool isMember;
  final MembershipStatus? membershipStatus;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');
    final status =
        membershipStatus ?? (isMember ? MembershipStatus.confirmed : null);

    final badgeLabel = switch (status) {
      MembershipStatus.confirmed => 'Confirmed',
      MembershipStatus.waitlisted => 'Waitlisted',
      null => event.isFull ? 'Waitlist open' : 'Available',
    };
    final badgeTone = switch (status) {
      MembershipStatus.confirmed => BadgeTone.positive,
      MembershipStatus.waitlisted => BadgeTone.warning,
      null => event.isFull ? BadgeTone.warning : BadgeTone.neutral,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(label: badgeLabel, tone: badgeTone),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.schedule,
              text: dateFormat.format(event.startsAt),
            ),
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.place_outlined, text: event.location),
            if (event.capacity > 0) ...[
              const SizedBox(height: 14),
              CapacityIndicator(event: event),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: status != null
                  ? OutlinedButton(
                      onPressed: onTap,
                      child: Text(
                        status == MembershipStatus.waitlisted
                            ? 'View Waitlist'
                            : 'View Shift',
                      ),
                    )
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
                          : Text(event.isFull ? 'Join Waitlist' : 'Join Shift'),
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
        const SizedBox(width: 1),
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
