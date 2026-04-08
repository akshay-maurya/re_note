import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:re_note/providers/sync_provider.dart';
import 'package:re_note/ui/note_card.dart';
import 'package:re_note/ui/note_editor.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SyncProvider>();
    final notes = provider.notes;
    final isSyncing = provider.syncManager.status.isSyncing;
    final currentError = provider.syncErrorMessage;

    // Error UX: keep the previous behavior from HomeScreen.
    if (currentError != null && currentError != _lastError) {
      _lastError = currentError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentError),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                provider.syncManager.triggerSync();
              },
            ),
          ),
        );
      });
    } else if (currentError == null) {
      _lastError = null;
    }

    return Column(
      children: [
        if (!provider.isSyncEnabled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(top: 8),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(140),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sync disabled. Log in to save data.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (isSyncing) const LinearProgressIndicator(),
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NoteEditor(note: note),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

