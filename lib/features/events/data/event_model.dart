enum MembershipStatus {
  confirmed,
  waitlisted;

  static MembershipStatus fromDatabase(String value) {
    return value == 'waitlisted'
        ? MembershipStatus.waitlisted
        : MembershipStatus.confirmed;
  }

  String get databaseValue => name;
}

class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    this.capacity = 0,
    this.confirmedCount = 0,
    this.waitlistedCount = 0,
  });

  final String id;
  final String title;
  final String? description;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final int confirmedCount;
  final int waitlistedCount;

  int get spotsRemaining =>
      (capacity - confirmedCount).clamp(0, capacity).toInt();

  bool get isFull => capacity > 0 && confirmedCount >= capacity;

  double get fillRatio =>
      capacity <= 0 ? 0 : (confirmedCount / capacity).clamp(0, 1);

  EventModel copyWith({
    int? capacity,
    int? confirmedCount,
    int? waitlistedCount,
  }) {
    return EventModel(
      id: id,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      capacity: capacity ?? this.capacity,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      waitlistedCount: waitlistedCount ?? this.waitlistedCount,
    );
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String,
      startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(map['ends_at'] as String).toLocal(),
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      confirmedCount: (map['confirmed_count'] as num?)?.toInt() ?? 0,
      waitlistedCount: (map['waitlisted_count'] as num?)?.toInt() ?? 0,
    );
  }
}
