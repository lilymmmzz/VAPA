import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/note.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red));
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';
    if (_isEditing) {
      await notesProvider.updateNote(widget.note!.id, userId, _titleController.text.trim(), _contentController.text.trim());
    } else {
      await notesProvider.createNote(userId, _titleController.text.trim(), _contentController.text.trim());
    }
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
        title: Text(_isEditing ? 'Edit Note' : 'New Note', style: const TextStyle(color: VapaColors.textPrimary, fontSize: 16)),
        iconTheme: const IconThemeData(color: VapaColors.purple),
        actions: [
          TextButton.icon(
            onPressed: _saveNote,
            icon: const Icon(Icons.check, color: VapaColors.tealLight, size: 18),
            label: const Text('Save', style: TextStyle(color: VapaColors.tealLight, fontSize: 14)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: VapaColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: VapaColors.textMuted),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const Divider(color: VapaColors.border, height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 15, color: VapaColors.textSecondary, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Start writing...',
                      hintStyle: TextStyle(color: VapaColors.textMuted),
                      border: InputBorder.none,
                      filled: false,
                    ),
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