import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all notes for a user
  Stream<List<Note>> getNotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromMap(doc.data())).toList();
    });
  }

  // Create a new note
  Future<void> createNote(Note note) async {
    await _firestore
        .collection('users')
        .doc(note.userId)
        .collection('notes')
        .doc(note.id)
        .set(note.toMap());
  }

  // Update an existing note
  Future<void> updateNote(Note note) async {
    await _firestore
        .collection('users')
        .doc(note.userId)
        .collection('notes')
        .doc(note.id)
        .update(note.toMap());
  }

  // Delete a note
  Future<void> deleteNote(String userId, String noteId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}