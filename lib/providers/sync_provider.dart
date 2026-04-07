import 'package:flutter/material.dart';
import 'package:re_note/models/note.dart';
import 'package:re_note/models/sync_action.dart';
import 'package:re_note/repositories/sync_repository.dart';
import 'package:re_note/services/firestore_service.dart';
import 'package:re_note/services/sync_manager.dart';
import 'package:uuid/uuid.dart';

class SyncProvider extends ChangeNotifier {
  final SyncRepository repository;
  final SyncManager syncManager;
  final FirestoreService firestoreService;

  SyncProvider({
    required this.repository,
    required this.syncManager,
    required this.firestoreService,
  }) {
    // Listen to SyncManager updates (like logs or sync states) to rebuild UI
    syncManager.addListener(_onSyncManagerUpdated);
  }

  String? get syncErrorMessage => syncManager.status.syncErrorMessage;

  void _onSyncManagerUpdated() {
    notifyListeners();
  }

  List<Note> get notes => repository.getNotes();
  int get queueSize => syncManager.status.pendingCount;

  Future<void> addNote(String title, String content) async {
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await repository.saveNote(note);
    notifyListeners();
    syncManager.triggerSync();
  }

  Future<void> updateNote(Note note, String newTitle, String newContent) async {
    final updatedNote = note.copyWith(
      title: newTitle,
      content: newContent,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await repository.saveNote(updatedNote);
    notifyListeners();
    syncManager.triggerSync();
  }

  Future<void> deleteNote(Note note) async {
    final deletedNote = note.copyWith(
      isDeleted: true,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await repository.saveNote(deletedNote);
    notifyListeners();
    syncManager.triggerSync();
  }

  Future<void> likeItem(String itemId) async {
    await repository.recordAction(ActionType.like, {'itemId': itemId});
    notifyListeners();
    syncManager.triggerSync();
  }

  @override
  void dispose() {
    syncManager.removeListener(_onSyncManagerUpdated);
    super.dispose();
  }
}
