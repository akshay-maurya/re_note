import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:re_note/models/note.dart';
import 'package:re_note/models/sync_action.dart' as action_model;
import 'package:re_note/services/auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService authService;

  FirestoreService({required this.authService});

  String get userId {
    final uid = authService.userId;
    if (uid == null) {
      throw Exception('User is not authenticated');
    }
    return uid;
  }

  Future<void> upsertNote(Note note) async {
    // Idempotency constraint: Uses Note's UUID.
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.id)
        .set(note.toMap(), SetOptions(merge: true));
  }

  Future<void> processAction(action_model.SyncAction action) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('actions')
        .doc(action.id)
        .set({
          'type': action.actionType.name,
          'payload': action.payload,
          'createdAt': action.createdAt.toUtc().toIso8601String(),
        });
  }

  Future<void> deleteNote(String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(id)
        .delete();
  }
}
