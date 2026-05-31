import 'package:flutter/material.dart';
import 'package:local_ai_chat/screens/task_screen.dart';
import 'package:local_ai_chat/services/task_services.dart';
import 'models/task.dart';
import 'screens/chat_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Task> _tasks = [];
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    // Load saved tasks when app starts
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.loadTasks();
    setState(() => _tasks = tasks);
  }

  Future<void> _addTask(String title) async {
    final updated = await _taskService.addTask(_tasks, title);
    setState(() => _tasks = updated);
  }

  Future<void> _toggleTask(String id) async {
    final updated = await _taskService.toggleTask(_tasks, id);
    setState(() => _tasks = updated);
  }

  Future<void> _deleteTask(String id) async {
    final updated = await _taskService.deleteTask(_tasks, id);
    setState(() => _tasks = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'AI Assistant' : 'My Tasks'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      // IndexedStack keeps both screens alive in memory
      // so chat history isn't lost when switching tabs
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ChatScreen(onAddTask: _addTask),
          TasksScreen(
            tasks: _tasks,
            onToggle: _toggleTask,
            onDelete: _deleteTask,
            onAdd: _addTask,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}