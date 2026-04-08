import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_note/providers/sync_provider.dart';
import 'package:re_note/ui/email_sign_in_screen.dart';

class CloudSyncTab extends StatelessWidget {
  const CloudSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SyncProvider>();
    final isSyncing = provider.syncManager.status.isSyncing;

    if (!provider.isSyncEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 72),
              const SizedBox(height: 16),
              Text(
                'Login to back up your notes safely',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailSignInScreen(),
                    ),
                  );
                },
                child: const Text('Sign in with Email'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signed in as',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            provider.userEmail ?? 'Unknown user',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (provider.isReconciling)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Reconciling local and cloud data...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            )
          else
            Text(
              'Queue: ${provider.queueSize} item(s)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
              onPressed: () async {
                if (provider.isReconciling || isSyncing) return;
                await provider.syncNow();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () async {
                if (provider.isReconciling || isSyncing) return;
                await provider.logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

