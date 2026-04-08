import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  User? get currentUser => _auth.currentUser;

  String? get email => _auth.currentUser?.email;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      // Kept for backwards compatibility; the app now starts signed-out.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to sign in anonymously: $e');
      }
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
