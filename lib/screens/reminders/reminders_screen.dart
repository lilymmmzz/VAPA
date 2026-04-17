import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminders_provider.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final remindersProvider = Provider.of<RemindersProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return Scaffold(
      body: remindersProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : remindersProvider.reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.alarm_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reminders yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first reminder',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: remindersProvider.reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = remindersProvider.reminders[index];
                    final isOverdue =
                        reminder.scheduledDateTime.isBefore(DateTime.now()) &&
                            !reminder.isCompleted;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Checkbox(
                          value: reminder.isCompleted,
                          onChanged: (_) {
                            remindersProvider.completeReminder(
                                userId, reminder.id);
                          },
                        ),
                        title: Text(
                          reminder.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: reminder.isCompleted
                                ? Colors.grey
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reminder.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                reminder.description,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: isOverdue ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${reminder.scheduledDateTime.day}/${reminder.scheduledDateTime.month}/${reminder.scheduledDateTime.year} '
                                  '${reminder.scheduledDateTime.hour.toString().padLeft(2, '0')}:${reminder.scheduledDateTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isOverdue ? Colors.red : Colors.grey,
                                    fontWeight: isOverdue
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Reminder'),
                                content: const Text(
                                    'Are you sure you want to delete this reminder?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      remindersProvider.deleteReminder(
                                          userId, reminder.id);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddReminderScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}