import 'package:flutter/material.dart';
import 'package:re_note/models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!note.isSynced)
                    const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.orange,
                      size: 20,
                    )
                  else
                    const Icon(Icons.check, color: Colors.grey, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
