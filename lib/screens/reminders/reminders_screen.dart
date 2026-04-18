import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
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
      backgroundColor: VapaColors.bg,
      body: remindersProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: VapaColors.tealLight))
          : remindersProvider.reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: VapaColors.surface, border: Border.all(color: VapaColors.border)),
                        child: const Icon(Icons.alarm_outlined, size: 32, color: VapaColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      const Text('No reminders yet', style: TextStyle(fontSize: 16, color: VapaColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Tap + to create your first reminder', style: TextStyle(color: VapaColors.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 600,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: remindersProvider.reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = remindersProvider.reminders[index];
                        final isOverdue = reminder.scheduledDateTime.isBefore(DateTime.now()) && !reminder.isCompleted;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: VapaColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isOverdue ? Colors.red.withOpacity(0.4) : VapaColors.border, width: 0.5),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Checkbox(
                              value: reminder.isCompleted,
                              onChanged: (_) => remindersProvider.completeReminder(userId, reminder.id),
                              activeColor: VapaColors.teal,
                              side: const BorderSide(color: VapaColors.border),
                            ),
                            title: Text(
                              reminder.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                                color: reminder.isCompleted ? VapaColors.textMuted : VapaColors.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (reminder.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(reminder.description, style: const TextStyle(color: VapaColors.textMuted, fontSize: 12)),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: isOverdue ? Colors.red : VapaColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${reminder.scheduledDateTime.day}/${reminder.scheduledDateTime.month}/${reminder.scheduledDateTime.year} '
                                      '${reminder.scheduledDateTime.hour.toString().padLeft(2, '0')}:${reminder.scheduledDateTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 11, color: isOverdue ? Colors.red : VapaColors.textMuted, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: VapaColors.surface,
                                  title: const Text('Delete Reminder', style: TextStyle(color: VapaColors.textPrimary, fontSize: 16)),
                                  content: const Text('Are you sure?', style: TextStyle(color: VapaColors.textSecondary)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: VapaColors.tealLight))),
                                    TextButton(onPressed: () { remindersProvider.deleteReminder(userId, reminder.id); Navigator.pop(context); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddReminderScreen())),
        backgroundColor: VapaColors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}