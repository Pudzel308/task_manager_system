import 'package:sqflite/sqflite.dart';
import '../../models/task.dart';

class InvalidTaskTitleException implements Exception {
  final String message;
  const InvalidTaskTitleException([
    this.message = 'Enter a task title before adding it.',
  ]);

  @override
  String toString() => message;
}

class TaskNotFoundException implements Exception {
  final int id;
  const TaskNotFoundException(this.id);

  @override
  String toString() => 'Task $id no longer exists.';
}

class TaskRepository {
  final Database _database;

  TaskRepository(this._database);

  Future<int> create(String title) {
    final cleanedTitle = title.trim();
    if (cleanedTitle.isEmpty) {
      throw const InvalidTaskTitleException();
    }
    return _database.insert('tasks', {'title': cleanedTitle});
  }

  Future<List<Task>> getAll() async {
    final rows = await _database.query('tasks', orderBy: 'id DESC');
    return rows.map(Task.fromMap).toList();
  }

  Future<void> setCompleted(int id, bool isCompleted) async {
    final rowsAffected = await _database.update(
      'tasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rowsAffected == 0) {
      throw TaskNotFoundException(id);
    }
  }

  Future<void> delete(int id) async {
    final rowsDeleted = await _database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rowsDeleted == 0) {
      throw TaskNotFoundException(id);
    }
  }
}
