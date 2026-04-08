import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:re_note/services/auth_service.dart';

sealed class EmailAuthResult {
  const EmailAuthResult();
}

class EmailAuthSuccess extends EmailAuthResult {
  const EmailAuthSuccess();
}

class EmailAuthUserNotFound extends EmailAuthResult {
  const EmailAuthUserNotFound();
}

class EmailAuthFailure extends EmailAuthResult {
  final String message;
  const EmailAuthFailure(this.message);
}

class EmailAuthProvider extends ChangeNotifier {
  final AuthService authService;

  EmailAuthProvider({required this.authService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<EmailAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    setError(null);

    try {
      await authService.signInWithEmail(email: email, password: password);
      return const EmailAuthSuccess();
    } on FirebaseAuthException catch (e) {
      // Depending on project settings, Firebase may return `invalid-credential`
      // instead of `user-not-found` to prevent email enumeration.
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return const EmailAuthUserNotFound();
      }
      return EmailAuthFailure(e.message ?? e.code);
    } catch (e) {
      return EmailAuthFailure(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<EmailAuthResult> register({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    setError(null);

    try {
      await authService.registerWithEmail(email: email, password: password);
      return const EmailAuthSuccess();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return const EmailAuthFailure(
          'An account already exists for this email. Try signing in (or reset your password).',
        );
      }
      return EmailAuthFailure(e.message ?? e.code);
    } catch (e) {
      return EmailAuthFailure(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
