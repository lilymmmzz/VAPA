import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';

class RemindersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all reminders for a user
  Stream<List<Reminder>> getReminders(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .orderBy('scheduledDateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Reminder.fromMap(doc.data()))
          .toList();
    });
  }

  // Create a new reminder
  Future<void> createReminder(Reminder reminder) async {
    await _firestore
        .collection('users')
        .doc(reminder.userId)
        .collection('reminders')
        .doc(reminder.id)
        .set(reminder.toMap());
  }

  // Update a reminder
  Future<void> updateReminder(Reminder reminder) async {
    await _firestore
        .collection('users')
        .doc(reminder.userId)
        .collection('reminders')
        .doc(reminder.id)
        .update(reminder.toMap());
  }

  // Delete a reminder
  Future<void> deleteReminder(String userId, String reminderId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }

  // Mark reminder as completed
  Future<void> completeReminder(String userId, String reminderId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .doc(reminderId)
        .update({'isCompleted': true});
  }
}