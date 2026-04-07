import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_note/models/note.dart';
import 'package:re_note/providers/sync_provider.dart';

class NoteEditor extends StatefulWidget {
  final Note? note;

  const NoteEditor({super.key, this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final provider = context.read<SyncProvider>();
    if (widget.note == null) {
      provider.addNote(title, content);
    } else {
      provider.updateNote(widget.note!, title, content);
    }
    Navigator.pop(context);
  }

  void _deleteNote() {
    if (widget.note != null) {
      context.read<SyncProvider>().deleteNote(widget.note!);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          if (widget.note != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteNote),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Title',
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Note',
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
