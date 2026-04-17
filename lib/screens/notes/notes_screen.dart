import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: notesProvider.setSearchQuery,
              style: const TextStyle(color: Color(0xFFCCC9F5)),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: const TextStyle(color: Color(0xFF7777AA)),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF534AB7)),
                filled: true,
                fillColor: const Color(0xFF12122A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF534AB7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF534AB7)),
                ),
              ),
            ),
          ),
          // Notes List
          Expanded(
            child: notesProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7F77DD)))
                : notesProvider.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF12122A),
                                border: Border.all(
                                    color: const Color(0xFF534AB7)),
                              ),
                              child: const Icon(
                                Icons.note_outlined,
                                size: 40,
                                color: Color(0xFF534AB7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No notes yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFFAFA9EC),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap + to create your first note',
                              style: TextStyle(color: Color(0xFF534AB7)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notesProvider.notes.length,
                        itemBuilder: (context, index) {
                          final note = notesProvider.notes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12122A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF3C3489)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                note.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFCCC9F5),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFF7777AA)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Updated: ${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF534AB7),
                                    ),
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
                                      backgroundColor:
                                          const Color(0xFF12122A),
                                      title: const Text(
                                        'Delete Note',
                                        style: TextStyle(
                                            color: Color(0xFFCCC9F5)),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to delete this note?',
                                        style: TextStyle(
                                            color: Color(0xFF7777AA)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel',
                                              style: TextStyle(
                                                  color:
                                                      Color(0xFF7F77DD))),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            notesProvider.deleteNote(
                                                userId, note.id);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NoteEditorScreen(note: note),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NoteEditorScreen()),
          );
        },
        backgroundColor: const Color(0xFF534AB7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}