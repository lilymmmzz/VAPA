class Reminder {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime scheduledDateTime;
  final bool isCompleted;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.scheduledDateTime,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledDateTime: DateTime.parse(map['scheduledDateTime']),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Reminder copyWith({bool? isCompleted}) {
    return Reminder(
      id: id,
      userId: userId,
      title: title,
      description: description,
      scheduledDateTime: scheduledDateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}