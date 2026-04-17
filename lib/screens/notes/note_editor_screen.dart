import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    _titleController =
        TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';

    if (_isEditing) {
      await notesProvider.updateNote(
        widget.note!.id,
        userId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
    } else {
      await notesProvider.createNote(
        userId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        foregroundColor: const Color(0xFFAFA9EC),
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Note' : 'New Note',
          style: const TextStyle(color: Color(0xFFAFA9EC)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF7F77DD)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF7F77DD)),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title Field
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCCC9F5),
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Color(0xFF534AB7)),
                border: InputBorder.none,
                filled: false,
              ),
            ),
            const Divider(color: Color(0xFF3C3489)),
            // Content Field
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFAFA9EC),
                ),
                decoration: const InputDecoration(
                  hintText: 'Start writing...',
                  hintStyle: TextStyle(color: Color(0xFF534AB7)),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}