import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
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
      backgroundColor: VapaColors.bg,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TextField(
                  onChanged: notesProvider.setSearchQuery,
                  style: const TextStyle(color: VapaColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    hintStyle: const TextStyle(color: VapaColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: VapaColors.purple, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: VapaColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.tealLight, width: 1.5)),
                  ),
                ),
              ),
            ),
          ),
          // Notes list
          Expanded(
            child: notesProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: VapaColors.tealLight))
                : notesProvider.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: VapaColors.surface, border: Border.all(color: VapaColors.border)),
                              child: const Icon(Icons.note_outlined, size: 32, color: VapaColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            const Text('No notes yet', style: TextStyle(fontSize: 16, color: VapaColors.textSecondary)),
                            const SizedBox(height: 4),
                            const Text('Tap + to create your first note', style: TextStyle(color: VapaColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 600,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: notesProvider.notes.length,
                            itemBuilder: (context, index) {
                              final note = notesProvider.notes[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: VapaColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: VapaColors.border, width: 0.5),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: VapaColors.textPrimary)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: VapaColors.textMuted, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text('Updated: ${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}', style: const TextStyle(fontSize: 11, color: VapaColors.textMuted)),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: VapaColors.surface,
                                        title: const Text('Delete Note', style: TextStyle(color: VapaColors.textPrimary, fontSize: 16)),
                                        content: const Text('Are you sure?', style: TextStyle(color: VapaColors.textSecondary)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: VapaColors.tealLight))),
                                          TextButton(onPressed: () { notesProvider.deleteNote(userId, note.id); Navigator.pop(context); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note))),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditorScreen())),
        backgroundColor: VapaColors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}