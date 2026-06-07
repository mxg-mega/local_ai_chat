import '../models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaskService {
  static const String _storageKey = 'tasks';

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);

    if (tasksJson == null) {
      return [];
    }

    final List<dynamic> decode = jsonDecode(tasksJson);
    return decode.map((json) => Task.fromJson(json)).toList();
  }

  Future<List<Task>> addTask(List<Task> currentTasks, String title) async {
    final prefs = await SharedPreferences.getInstance();

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: '',
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    final updated = [...currentTasks, newTask];

    final encode = jsonEncode(updated.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encode);

    // String? tasksJson = prefs.getString(_storageKey);
    // if (tasksJson == null) {
    //   throw Exception("Could not load/find: 'Tasks'");
    // }

    // List<dynamic> decode = jsonDecode(tasksJson);
    // decode.add(task.toJson());

    // bool status = await prefs.setString(_storageKey, jsonEncode(decode));
    return updated;
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    // String? oldTasksJson = prefs.getString(_storageKey);

    // if (oldTasksJson == null) {
    //   throw Exception("Could not load/find: 'Tasks'");
    // }

    // final decode = jsonDecode(oldTasksJson) as List<dynamic>;

    // decode.addAll(tasks.map((task) => task.toJson()).toList());

    // final status = await prefs.setString(_storageKey, jsonEncode(decode));

    // if (!status) {
    //   throw Exception("Failed to save tasks");
    // }

    // Convert each Task to a Map, then encode the whole list as a JSON string
    final String encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // Future<Task?> updateTask(String id, List<Task> currentTasks, Map<String, dynamic> updates) async {

  //   int index = currentTasks.indexWhere((task) => task.id == id);

  //   if (index == -1) {
  //     throw Exception("Task with id '$id' not found");
  //   }

  //   Task updatedTask = currentTasks[index].copyWith(
  //     title: updates['title'] as String?,
  //     description: updates['description'] as String?,
  //     isCompleted: updates['is_completed'] as bool?
  //   );
  //   currentTasks[index] = updatedTask;

  //   return updatedTask;
  // }

  // Add this method to your existing TaskService class
  Future<List<Task>> updateTask(
    List<Task> currentTasks,
    String id,
    String newTitle,
  ) async {
    final updated = currentTasks.map((t) {
      if (t.id == id) t.title = newTitle;
      return t;
    }).toList();
    await saveTasks(updated);
    return updated;
  }

  Future<List<Task>> toggleTask(List<Task> currentTasks, String id) async {
    // int index = currentTasks.indexWhere((task) => task.id == id);

    // if (index == -1) {
    //   throw Exception("Task with id '$id' not found");
    // }

    // Task toggled = currentTasks[index].copyWith(isCompleted: !currentTasks[index].isCompleted);
    // currentTasks[index] = toggled;

    // await saveTasks(currentTasks);

    // return currentTasks;

    final updated = currentTasks.map((t) {
      if (t.id == id) t.isCompleted = !t.isCompleted;
      return t;
    }).toList();
    await saveTasks(updated);
    return updated;
  }

  Future<List<Task>> deleteTask(List<Task> currentTasks, String id) async {
    final updated = currentTasks.where((t) => t.id != id).toList();
    await saveTasks(updated);
    return updated;
  }
}
