import 'package:flutter/material.dart';
import 'package:re_note/models/note.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteTile({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(note.title),
      subtitle: Text(
        note.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildSyncIcon(context),
    );
  }

  Widget _buildSyncIcon(BuildContext context) {
    if (note.isSynced) {
      return const Icon(Icons.cloud_done, color: Colors.green);
    } else {
      // Show syncing spinner or cloud-off based on connectivity
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: Colors.grey),
          SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }
  }
}
