import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all moods for a user
  Stream<List<Mood>> getMoods(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Mood.fromMap(doc.data())).toList();
    });
  }

  // Save a mood
  Future<void> saveMood(Mood mood) async {
    await _firestore
        .collection('users')
        .doc(mood.userId)
        .collection('moods')
        .doc(mood.id)
        .set(mood.toMap());
  }

  // Delete a mood
  Future<void> deleteMood(String userId, String moodId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .doc(moodId)
        .delete();
  }

  // Check if mood logged today
  Future<bool> hasMoodToday(String userId) async {
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day);
    final endOfDay =
        DateTime(today.year, today.month, today.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .where('createdAt',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('createdAt',
            isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    return snapshot.docs.isNotEmpty;
  }
}