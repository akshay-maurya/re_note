import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:re_note/models/sync_state.dart';
import 'package:re_note/models/sync_action.dart' as action_model;
import 'package:re_note/repositories/sync_repository.dart';
import 'package:re_note/services/firestore_service.dart';
import 'package:re_note/services/auth_service.dart';

class SyncManager extends ChangeNotifier {
  final SyncRepository repository;
  final FirestoreService firestoreService;
  final AuthService authService;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  SyncState _status = SyncState(pendingCount: 0, isSyncing: false, logs: []);
  SyncState get status => _status;

  Timer? _retryTimer;
  int _retryCount = 0;

  SyncManager({
    required this.repository,
    required this.firestoreService,
    required this.authService,
  }) {
    _updatePendingCount();
    _initConnectivityListener();
  }

  void _addLog(String message) {
    final newLogs = List<String>.from(_status.logs)..add(message);
    _status = _status.copyWith(logs: newLogs);
    notifyListeners();
  }

  void _updatePendingCount() {
    _status = _status.copyWith(pendingCount: repository.queueSize);
    notifyListeners();
  }

  void triggerSync() {
    _updatePendingCount();
    if (_status.pendingCount > 0) {
      processFullQueue();
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _addLog('Connection restored');
        processFullQueue();
      } else {
        _addLog('Connection lost');
      }
    });
  }

  Future<void> processFullQueue() async {
    if (_status.isSyncing) return;
    // Auth-gated: do nothing when logged out.
    if (authService.userId == null) return;

    _status = _status.copyWith(syncErrorMessage: null); // Reset errors

    _updatePendingCount();
    if (_status.pendingCount == 0) {
      return;
    }

    _status = _status.copyWith(isSyncing: true);
    notifyListeners();
    _retryTimer?.cancel();

    _addLog('Starting sync for ${_status.pendingCount} items...');

    try {
      // Process Actions First
      final pendingActions = repository.actionBox.values
          .where((a) => a.status != action_model.SyncStatus.syncing)
          .toList();

      for (var action in pendingActions) {
        _addLog('Syncing Action ${action.actionType.name}...');
        action.status = action_model.SyncStatus.syncing;
        await action.save();

        await firestoreService.processAction(action);
        await action.delete(); // Remove on success
        _addLog('Action ${action.actionType.name} Synced');
      }

      // Process Notes
      final unsyncedNotes = repository.noteBox.values
          .where((n) => !n.isSynced)
          .toList();

      for (var note in unsyncedNotes) {
        _addLog('Syncing Note ${note.id}...');
        try {
          if (note.isDeleted) {
            await firestoreService.deleteNote(note.id);
            await repository.noteBox.delete(note.id);
            _addLog('Deleted Note ${note.id} Synced');
          } else {
            // Idempotency Logic: We use the Note's UUID as primary key natively via Firebase doc update
            await firestoreService.upsertNote(note);
            // Updates note in Hive to isSynced=true only AFTER successful response
            note.isSynced = true;
            await repository.noteBox.put(note.id, note);
            _addLog('Note ${note.id} Synced');
          }
        } catch (e) {
          final errorString = e.toString();
          if (errorString.contains('permission-denied') ||
              errorString.contains('network-unavailable') ||
              errorString.contains('unavailable')) {
            _status = _status.copyWith(
              syncErrorMessage: 'Sync Failed: Permission or Network Error',
            );
          } else {
            _status = _status.copyWith(
              syncErrorMessage: 'Sync Failed: $errorString',
            );
          }
          notifyListeners();
          _addLog('Sync failed for Note ${note.id}: $e');
          break; // Stop loop to prevent repeated errors
        }
      }

      _retryCount = 0; // reset on success
    } catch (e) {
      _addLog('Sync failed: $e');
      if (_retryCount < 1) {
        // Implement a single retry
        _scheduleRetry();
      } else {
        _addLog('Max retries reached. Waiting for next connectivity event.');
        _retryCount = 0;
      }
    } finally {
      _status = _status.copyWith(isSyncing: false);
      _updatePendingCount();
    }
  }

  void _scheduleRetry() {
    _retryCount++;
    _addLog('Scheduling retry in 5 seconds...');
    _retryTimer = Timer(const Duration(seconds: 5), () {
      processFullQueue();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
