import 'package:flutter/material.dart';

enum BadgeTone { neutral, positive, warning }

/// A small rounded status pill, e.g. "Available" / "Confirmed" on an
/// event card, or "Clocked In" / "Not Clocked In" on the attendance
/// panel.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      BadgeTone.positive => (const Color(0xFFE7F6EC), const Color(0xFF15803D)),
      BadgeTone.warning => (const Color(0xFFFDEDEA), const Color(0xFFB91C1C)),
      BadgeTone.neutral => (const Color(0xFFEDEFF3), const Color(0xFF444B57)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
