class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String? description;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String,
      startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(map['ends_at'] as String).toLocal(),
    );
  }
}
