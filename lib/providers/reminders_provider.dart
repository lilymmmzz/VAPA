import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../services/reminders_service.dart';

class RemindersProvider extends ChangeNotifier {
  final RemindersService _remindersService = RemindersService();
  List<Reminder> _reminders = [];
  bool _isLoading = false;

  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;

  // Load reminders for a user
  void loadReminders(String userId) {
    _isLoading = true;
    notifyListeners();

    _remindersService.getReminders(userId).listen((reminders) {
      _reminders = reminders;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Create a reminder
  Future<void> createReminder(
    String userId,
    String title,
    String description,
    DateTime scheduledDateTime,
  ) async {
    final reminder = Reminder(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      description: description,
      scheduledDateTime: scheduledDateTime,
      createdAt: DateTime.now(),
    );
    await _remindersService.createReminder(reminder);
  }

  // Complete a reminder
  Future<void> completeReminder(String userId, String reminderId) async {
    await _remindersService.completeReminder(userId, reminderId);
  }

  // Delete a reminder
  Future<void> deleteReminder(String userId, String reminderId) async {
    await _remindersService.deleteReminder(userId, reminderId);
  }

  // Clear reminders on logout
  void clearReminders() {
    _reminders = [];
    notifyListeners();
  }
}