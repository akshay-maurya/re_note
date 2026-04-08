import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:re_note/providers/sync_provider.dart';
import 'package:re_note/services/global_services.dart';
import 'package:re_note/ui/note_card.dart';
import 'package:re_note/ui/note_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SyncProvider>();
    final notes = provider.notes;
    final isSyncing = provider.syncManager.status.isSyncing;
    final currentError = provider.syncErrorMessage;

    // Edge Case UI: runtime error trigger
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

    return Scaffold(
      appBar: AppBar(title: const Text(GlobalServices.appName)),
      body: Column(
        children: [
          if (isSyncing) const LinearProgressIndicator(),
          if (notes.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No notes yet',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
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
                            builder: (context) => NoteEditor(note: note),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteEditor()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
