class Task {
  final int id;
  final String title;
  final bool isCompleted;

  const Task({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }
}
