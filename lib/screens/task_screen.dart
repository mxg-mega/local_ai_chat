import 'package:flutter/material.dart';
import '../models/task.dart';

class TasksScreen extends StatelessWidget {
  final List<Task> tasks;
  final Function(String id) onToggle;
  final Function(String id) onDelete;
  final Function(String title) onAdd;

  const TasksScreen({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter task title...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'No tasks yet!\nAdd one below or ask the AI.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final task = tasks[i];
                return ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => onToggle(task.id),
                    activeColor: Colors.deepPurple,
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onDelete(task.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}