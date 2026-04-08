import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:re_note/models/note.dart';
import 'package:re_note/models/sync_action.dart';
import 'package:re_note/repositories/sync_repository.dart';
import 'package:re_note/services/firestore_service.dart';
import 'package:re_note/services/auth_service.dart';
import 'package:re_note/services/sync_manager.dart';
import 'package:uuid/uuid.dart';

class SyncProvider extends ChangeNotifier {
  final SyncRepository repository;
  final SyncManager syncManager;
  final FirestoreService firestoreService;
  final AuthService authService;

  StreamSubscription<User?>? _authSubscription;
  bool _isReconciling = false;
  String? _lastReconciledUid;

  SyncProvider({
    required this.repository,
    required this.syncManager,
    required this.firestoreService,
    required this.authService,
  }) {
    // Listen to SyncManager updates (like logs or sync states) to rebuild UI
    syncManager.addListener(_onSyncManagerUpdated);

    // Auth gating + reconcile on login.
    _lastReconciledUid = null;

    final initialUid = authService.userId;
    if (initialUid != null) {
      _lastReconciledUid = initialUid;
      // First load when already signed in: reconcile once.
      reconcileData();
    }

    _authSubscription = authService.authStateChanges().listen((user) {
      if (user == null) {
        // Logged out: stop syncing (UI will update via isSyncEnabled).
        _lastReconciledUid = null;
        notifyListeners();
        return;
      }

      if (_lastReconciledUid != user.uid) {
        _lastReconciledUid = user.uid;
        reconcileData();
      }
    });
  }

  String? get syncErrorMessage => syncManager.status.syncErrorMessage;

  bool get isSyncEnabled => authService.userId != null;

  String? get userEmail => authService.email;

  bool get isReconciling => _isReconciling;

  void _setReconciling(bool value) {
    _isReconciling = value;
    notifyListeners();
  }

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
    if (isSyncEnabled) {
      syncManager.triggerSync();
    }
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
    if (isSyncEnabled) {
      syncManager.triggerSync();
    }
  }

  Future<void> deleteNote(Note note) async {
    final deletedNote = note.copyWith(
      isDeleted: true,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await repository.saveNote(deletedNote);
    notifyListeners();
    if (isSyncEnabled) {
      syncManager.triggerSync();
    }
  }

  Future<void> likeItem(String itemId) async {
    await repository.recordAction(ActionType.like, {'itemId': itemId});
    notifyListeners();
    if (isSyncEnabled) {
      syncManager.triggerSync();
    }
  }

  @override
  void dispose() {
    syncManager.removeListener(_onSyncManagerUpdated);
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> syncNow() async {
    if (!isSyncEnabled) return;
    if (_isReconciling) return;
    await syncManager.processFullQueue();
  }

  Future<void> logout() async {
    // Keep offline notes, but clear any queued remote actions to avoid cross-user sync.
    await repository.actionBox.clear();

    // Mark local notes as "not yet synced" so next reconcile/sync decides correctly.
    for (final note in repository.noteBox.values) {
      await repository.noteBox.put(note.id, note.copyWith(isSynced: false));
    }

    await authService.signOut();
  }

  Future<void> reconcileData() async {
    if (!isSyncEnabled) return;
    if (_isReconciling) return;

    _setReconciling(true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isNotEmpty &&
          connectivityResult.first == ConnectivityResult.none) {
        return;
      }

      // Fetch remote notes from Firestore.
      final remoteNotes = await firestoreService.fetchNotesForCurrentUser();
      final remoteById = {for (final n in remoteNotes) n.id: n};

      // Load all local notes from Hive (including tombstones).
      final localById = {for (final n in repository.noteBox.values) n.id: n};

      final allIds = <String>{...localById.keys, ...remoteById.keys};

      for (final id in allIds) {
        final local = localById[id];
        final remote = remoteById[id];

        Note chosen;
        bool shouldWriteRemote = false;
        bool remoteShouldBeDeleted = false;

        if (local == null && remote != null) {
          // Remote-only: bring it down locally.
          chosen = remote.copyWith(isSynced: true);
        } else if (local != null && remote == null) {
          // Local-only: push it up (unless it's deleted already).
          chosen = local.copyWith(isSynced: true);
          if (!local.isDeleted) shouldWriteRemote = true;
        } else if (local != null && remote != null) {
          final localWins =
              local.updatedAt.isAfter(remote.updatedAt) ||
              local.updatedAt.isAtSameMomentAs(remote.updatedAt);

          if (localWins) {
            chosen = local.copyWith(isSynced: true);
            shouldWriteRemote = true;
            remoteShouldBeDeleted = local.isDeleted;
          } else {
            chosen = remote.copyWith(isSynced: true);
            // Remote newer already exists, but if it represents deletion we still enforce it.
            shouldWriteRemote = remote.isDeleted;
            remoteShouldBeDeleted = remote.isDeleted;
          }
        } else {
          // Should never happen since allIds is built from keys.
          continue;
        }

        // Persist merged note locally first.
        await repository.noteBox.put(id, chosen);

        // Then reconcile with Firestore as needed.
        if (shouldWriteRemote) {
          if (remoteShouldBeDeleted) {
            await firestoreService.deleteNote(id);
          } else {
            await firestoreService.upsertNote(chosen);
          }
        }
      }

      // Flush any leftover queued actions/unsynced notes.
      await syncManager.processFullQueue();
    } finally {
      _setReconciling(false);
      notifyListeners();
    }
  }

  Future<void> fetchNotesFromServer() async {
    // Kept for backwards compatibility: reconciliation is the new behavior.
    await reconcileData();
  }
}
