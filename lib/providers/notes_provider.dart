import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/notes_service.dart';

class NotesProvider extends ChangeNotifier {
  final NotesService _notesService = NotesService();
  List<Note> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Note> get notes => _searchQuery.isEmpty
      ? _notes
      : _notes
          .where((note) =>
              note.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              note.content
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Load notes for a user
  void loadNotes(String userId) {
    _isLoading = true;
    notifyListeners();

    _notesService.getNotes(userId).listen((notes) {
      _notes = notes;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Search notes
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Create a note
  Future<void> createNote(String userId, String title, String content) async {
    final note = Note(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _notesService.createNote(note);
  }

  // Update a note
  Future<void> updateNote(String noteId, String userId, String title,
      String content) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedNote = Note(
      id: noteId,
      userId: userId,
      title: title,
      content: content,
      createdAt: _notes[noteIndex].createdAt,
      updatedAt: DateTime.now(),
    );
    await _notesService.updateNote(updatedNote);
  }

  // Delete a note
  Future<void> deleteNote(String userId, String noteId) async {
    await _notesService.deleteNote(userId, noteId);
  }

  // Clear notes on logout
  void clearNotes() {
    _notes = [];
    _searchQuery = '';
    notifyListeners();
  }
}