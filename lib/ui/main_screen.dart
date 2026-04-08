import 'package:flutter/material.dart';
import 'package:re_note/ui/cloud_sync_tab.dart';
import 'package:re_note/ui/note_editor.dart';
import 'package:re_note/ui/notes_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Notes' : 'Sync/Account'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [NotesTab(), CloudSyncTab()],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoteEditor()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (value) => setState(() => _selectedIndex = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Notes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload),
            label: 'Sync/Account',
          ),
        ],
      ),
    );
  }
}
