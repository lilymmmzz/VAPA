import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminders_provider.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});
  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: VapaColors.purple, surface: VapaColors.surface),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: VapaColors.purple, surface: VapaColors.surface),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _saveReminder() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date and time'), backgroundColor: Colors.red));
      return;
    }
    final scheduledDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final remindersProvider = Provider.of<RemindersProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';
    await remindersProvider.createReminder(userId, _titleController.text.trim(), _descriptionController.text.trim(), scheduledDateTime);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VapaColors.bg,
      appBar: AppBar(
        backgroundColor: VapaColors.bg,
        foregroundColor: VapaColors.textPrimary,
        elevation: 0,
        toolbarHeight: 48,
        title: const Text('New Reminder', style: TextStyle(fontSize: 16)),
        iconTheme: const IconThemeData(color: VapaColors.purple),
        actions: [
          TextButton.icon(
            onPressed: _saveReminder,
            icon: const Icon(Icons.check, color: VapaColors.tealLight, size: 18),
            label: const Text('Save', style: TextStyle(color: VapaColors.tealLight, fontSize: 14)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VapaColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Reminder title',
                    hintStyle: TextStyle(color: VapaColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const Divider(color: VapaColors.border, height: 1),
                const SizedBox(height: 14),
                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: const TextStyle(color: VapaColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: const TextStyle(color: VapaColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: VapaColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.tealLight, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Date & Time', style: TextStyle(color: VapaColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16, color: VapaColors.purple),
                        label: Text(
                          _selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(color: _selectedDate == null ? VapaColors.textMuted : VapaColors.textPrimary, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: VapaColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 16, color: VapaColors.purple),
                        label: Text(
                          _selectedTime == null ? 'Select Time' : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: _selectedTime == null ? VapaColors.textMuted : VapaColors.textPrimary, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: VapaColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _saveReminder,
                    icon: const Icon(Icons.alarm_add, size: 18),
                    label: const Text('Save Reminder', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: VapaColors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}