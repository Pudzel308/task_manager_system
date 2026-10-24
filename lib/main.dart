import 'package:flutter/material.dart';
import 'data/task_database.dart';
import 'data/task_repository.dart';
import 'screens/task_screen.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  try {
    final database = await openTaskDatabase();
    runApp(TaskApp(repository: TaskRepository(database)));
  } catch (_) {
    runApp(const DatabaseErrorApp());
  }
}

class TaskApp extends StatelessWidget {
  final TaskRepository repository;

  const TaskApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F5E)),
      ),
      home: TaskScreen(repository: repository),
    );
  }
}

class DatabaseErrorApp extends StatelessWidget {
  const DatabaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The task database could not be opened. '
              'Close the app and open it again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
