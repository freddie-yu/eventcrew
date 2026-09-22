class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.clockIn,
    this.clockOut,
  });

  final String id;
  final String eventId;
  final String userId;
  final DateTime clockIn;
  final DateTime? clockOut;

  /// True while there is no clock-out timestamp yet. This is the single
  /// source of truth for whether the UI shows "Clock In" or "Clock Out" —
  /// it is always derived from the persisted row, never a local flag.
  bool get isActive => clockOut == null;

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      userId: map['user_id'] as String,
      clockIn: DateTime.parse(map['clock_in'] as String).toLocal(),
      clockOut: map['clock_out'] == null
          ? null
          : DateTime.parse(map['clock_out'] as String).toLocal(),
    );
  }
}
