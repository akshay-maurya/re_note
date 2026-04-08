import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_note/providers/email_auth_provider.dart';
import 'package:re_note/providers/sync_provider.dart';

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn(BuildContext scopedContext) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authUi = scopedContext.read<EmailAuthProvider>();
    final navigator = Navigator.of(scopedContext);

    if (email.isEmpty || password.isEmpty) {
      authUi.setError('Email and password are required.');
      return;
    }

    final result = await authUi.signIn(email: email, password: password);
    if (!scopedContext.mounted) return;

    switch (result) {
      case EmailAuthSuccess():
        navigator.pop();
        return;
      case EmailAuthUserNotFound():
        final shouldRegister = await showDialog<bool>(
          context: scopedContext,
          builder: (context) => AlertDialog(
            title: const Text('Not registered'),
            content: Text(
              'No account found for $email.\n\nWould you like to register?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Register'),
              ),
            ],
          ),
        );

        if (!scopedContext.mounted) return;
        if (shouldRegister == true) {
          final registerResult =
              await authUi.register(email: email, password: password);
          if (!scopedContext.mounted) return;
          if (registerResult is EmailAuthSuccess) {
            navigator.pop();
          } else if (registerResult is EmailAuthFailure) {
            authUi.setError(registerResult.message);
          }
        }
        return;
      case EmailAuthFailure():
        authUi.setError(result.message);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<SyncProvider>().authService;

    return ChangeNotifierProvider<EmailAuthProvider>(
      create: (_) => EmailAuthProvider(authService: authService),
      child: Builder(
        builder: (context) {
          final authUi = context.watch<EmailAuthProvider>();
          final errorMessage = authUi.errorMessage;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Sign in'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          authUi.isLoading ? null : () => _signIn(context),
                      child: authUi.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in with Email'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

