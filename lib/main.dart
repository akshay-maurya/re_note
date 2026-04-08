import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:re_note/firebase_options.dart';
import 'package:re_note/models/note.dart';
import 'package:re_note/models/sync_action.dart' as action_model;
import 'package:re_note/providers/sync_provider.dart';
import 'package:re_note/repositories/sync_repository.dart';
import 'package:re_note/services/firestore_service.dart';
import 'package:re_note/services/global_services.dart';
import 'package:re_note/services/sync_manager.dart';
import 'package:re_note/services/auth_service.dart';
import 'package:re_note/ui/home_screen.dart';
import 'package:re_note/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(action_model.SyncActionAdapter());
  Hive.registerAdapter(action_model.ActionTypeAdapter());
  Hive.registerAdapter(action_model.SyncStatusAdapter());

  final noteBox = await Hive.openBox<Note>('notes');
  final actionBox = await Hive.openBox<action_model.SyncAction>('actions');

  final authService = AuthService();
  await authService.signInAnonymously();

  final firestoreService = FirestoreService(authService: authService);

  final repository = SyncRepository(noteBox: noteBox, actionBox: actionBox);

  final syncManager = SyncManager(
    repository: repository,
    firestoreService: firestoreService,
    authService: authService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SyncProvider(
            repository: repository,
            syncManager: syncManager,
            firestoreService: firestoreService,
            authService: authService,
          )..fetchNotesFromServer(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: GlobalServices.appName,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
