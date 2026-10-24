import 'package:flutter/material.dart';
import '../../data/task_repository.dart';
import '../../models/task.dart';

class TaskScreen extends StatefulWidget {
  final TaskRepository repository;

  const TaskScreen({super.key, required this.repository});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await widget.repository.getAll();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loadError = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load your tasks.';
        _isLoading = false;
      });
    }
  }

  Future<void> _retryLoad() async {
    setState(() => _isLoading = true);
    await _loadTasks();
  }

  Future<void> _runWrite({
    required Future<void> Function() action,
    required String failureMessage,
    String? successMessage,
  }) async {
    setState(() => _isBusy = true);
    try {
      await action();
      if (successMessage != null) _showMessage(successMessage);
      await _loadTasks();
    } on InvalidTaskTitleException catch (e) {
      _showMessage(e.message);
    } on TaskNotFoundException catch (e) {
      _showMessage(e.toString());
      await _loadTasks();
    } catch (_) {
      _showMessage(failureMessage);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _addTask() async {
    if (_isBusy) return;
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text;
    await _runWrite(
      action: () async {
        await widget.repository.create(title);
        _titleController.clear();
      },
      successMessage: 'Task added',
      failureMessage: 'Could not save the task. Try again.',
    );
  }

  Future<void> _setCompleted(Task task, bool isCompleted) {
    return _runWrite(
      action: () => widget.repository.setCompleted(task.id, isCompleted),
      failureMessage: 'Could not update the task. Try again.',
    );
  }

  Future<void> _deleteTask(Task task) {
    return _runWrite(
      action: () => widget.repository.delete(task.id),
      successMessage: 'Task deleted',
      failureMessage: 'Could not delete the task. Try again.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My tasks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a task title';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FilledButton(
                      onPressed: _isBusy ? null : _addTask,
                      child: const Text('Add task'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _retryLoad,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text('No tasks yet. Add your first task above.'),
      );
    }

    return ListView.separated(
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return ListTile(
          key: ValueKey(task.id),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: _isBusy
                ? null
                : (value) => _setCompleted(task, value ?? false),
          ),
          title: Text(
            task.title,
            style: task.isCompleted
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Theme.of(context).disabledColor,
                  )
                : null,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete task',
            onPressed: _isBusy ? null : () => _deleteTask(task),
          ),
        );
      },
    );
  }
}
