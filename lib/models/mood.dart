class Mood {
  final String id;
  final String userId;
  final int moodScore; // 1-5
  final String moodLabel;
  final String note;
  final DateTime createdAt;

  Mood({
    required this.id,
    required this.userId,
    required this.moodScore,
    required this.moodLabel,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'moodScore': moodScore,
      'moodLabel': moodLabel,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Mood.fromMap(Map<String, dynamic> map) {
    return Mood(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      moodScore: map['moodScore'] ?? 3,
      moodLabel: map['moodLabel'] ?? 'Okay',
      note: map['note'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}