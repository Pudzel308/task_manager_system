# Local Task Manager

IT 126 – Module 3, Lesson 2 (Local Storage and Database Operations)

A single-screen Flutter app that saves tasks in a local SQLite database through `sqflite`, so tasks are still there after the app is closed and reopened. All database access goes through a `TaskRepository`.

## Features

- Add a task with a text field and button
- Saved tasks load when the screen opens
- Mark a task as completed (or undo it) with the checkbox
- Delete a task
- Empty and whitespace-only titles are rejected
- Database errors show an error message instead of a success message

## Project structure

```
lib/
├── main.dart                     # Opens the database, starts the app
├── models/
│   └── task.dart                 # Task class (row <-> Dart object)
├── data/
│   ├── task_database.dart        # openTaskDatabase(): path, tasks table
│   └── task_repository.dart      # create / getAll / setCompleted / delete
└── screens/
    └── task_screen.dart          # The UI (never runs SQL directly)
```

## Database

```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0
);
```

## How to run

Requires the Flutter SDK. `sqflite` supports Android, iOS, and macOS, so run on an emulator, simulator, or device.

```bash
flutter pub get
flutter run
```

If the platform folders (`android/`, `ios/`) are missing, generate them once with `flutter create .` in this folder, then run the commands above.

To check persistence: add a few tasks, fully close the app (swipe it away), and open it again. The tasks should still be listed.

## Reflection

### 1. Why does the application use SQLite instead of relying only on a Dart list?

A Dart list lives in memory (RAM), and that memory is released when the app process ends, so every task would be gone on the next launch. My app writes each task to a `tasks.db` file on the device with `sqflite`, and `TaskScreen` reads the records back through `repository.getAll()` when it opens. SQLite also lets me find, update, and delete a specific record with a query, and it enforces rules such as `NOT NULL` on the title. A plain list would need a custom file format and my own load/save code, and that gets harder to manage as the number of tasks grows.

### 2. What is the purpose of the primary key in the tasks table?

The `id` column uniquely identifies each task. Two tasks can have the same title, so the title cannot safely identify a row. In my repository, `setCompleted()` and `delete()` both use `where: 'id = ?'` with the task's ID, so only that one row is changed. SQLite assigns the ID automatically (`AUTOINCREMENT`), so the app never has to generate it. The `Task` model carries the ID, which lets the UI tell the repository exactly which task the user tapped.

### 3. How does the repository simplify the UI's interaction with the database?

`TaskScreen` only calls `create()`, `getAll()`, `setCompleted()`, and `delete()`. It does not know the table name, column names, or SQL, and it receives `Task` objects instead of raw maps. The repository also keeps the data rules in one place: it trims the title and rejects an empty one, and it throws `TaskNotFoundException` when an update or delete matches no row. The UI only has to call these methods, catch the errors, and show the right message. If I change how data is stored or queried, I edit the repository and the screen can stay the same.

### 4. What would happen if a task were removed from the displayed list but not deleted from SQLite?

The record would stay in the database. The screen would look correct until the next time the tasks are loaded, such as after a restart, and then the "deleted" task would reappear. The UI and the stored data would no longer match. To avoid this, my app deletes the row through `repository.delete(id)` first and reloads the list from the database only after that call succeeds. If the delete fails, the task stays in the list and an error message is shown.

### 5. If the database schema later needed a new column for task priority, what parts of the application might need to change?

- **Database setup (`task_database.dart`):** Add the column to the `CREATE TABLE` statement. Because `onCreate` only runs for brand-new databases, I would also raise `version` to 2 and add an `onUpgrade` migration such as `ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 0`, so existing users keep their tasks.
- **Model (`task.dart`):** Add a `priority` field and read it in `Task.fromMap()`.
- **Repository (`task_repository.dart`):** Accept a priority in `create()`, include it in the inserted values, and optionally sort or filter by it in `getAll()`.
- **UI (`task_screen.dart`):** Add an input for choosing a priority and show it in each task row, with validation if needed.

Because the SQL is confined to the repository and database file, the UI changes are limited to the new input and display.
