import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_model.dart';

class CapacityIndicator extends StatelessWidget {
  const CapacityIndicator({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    if (event.capacity <= 0) return const SizedBox.shrink();

    final label = '${event.confirmedCount} of ${event.capacity} staffed';
    final trailing = event.isFull
        ? event.waitlistedCount == 0
            ? 'Waitlist open'
            : '${event.waitlistedCount} waiting'
        : '${event.spotsRemaining} spots';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                color: event.isFull
                    ? AppTheme.warning
                    : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: event.fillRatio,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              event.isFull ? AppTheme.warning : AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
