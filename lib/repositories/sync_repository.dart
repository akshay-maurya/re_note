import 'package:hive/hive.dart';
import 'package:re_note/models/note.dart';
import 'package:re_note/models/sync_action.dart';
import 'package:uuid/uuid.dart';

class SyncRepository {
  final Box<Note> noteBox;
  final Box<SyncAction> actionBox;
  final Uuid _uuid = const Uuid();

  SyncRepository({required this.noteBox, required this.actionBox});

  List<Note> getNotes() {
    return noteBox.values.where((note) => !note.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveNote(Note note) async {
    // When a user creates/edits a note, save it to Hive immediately with isSynced = false
    note.isSynced = false;
    await noteBox.put(note.id, note);
    // Also push a sync action for it optionally, or we can just iterate notes.
    // The prompt requires to "iterate through all isSynced = false notes in Hive and 'push' them".
  }

  Future<void> recordAction(
    ActionType type,
    Map<String, dynamic> payload,
  ) async {
    final action = SyncAction(
      id: _uuid.v4(),
      actionType: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await actionBox.put(action.id, action);
  }

  int get queueSize =>
      actionBox.length + noteBox.values.where((n) => !n.isSynced).length;
}
