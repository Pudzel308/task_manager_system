import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> openTaskDatabase() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'tasks.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
}
