import 'package:flutter/material.dart';
import 'package:local_ai_chat/models/task.dart';
import 'package:local_ai_chat/services/ai_services.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  // We pass a callback so chat can trigger task creation in the parent
  final Function(String taskTitle) onAddTask;
  final Function(String id) onToggleTask;
  final Function(String id) onDeleteTask;
  final Function(String id, String newTitle) onUpdateTask;
  final List<Task> currentTasks; // 👈 so we can pass to AI

  const ChatScreen({
    super.key,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onUpdateTask,
    required this.currentTasks,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();

  final List<Message> _messages = [];
  // We keep a separate history list formatted for the API
  final List<Map<String, String>> _history = [];
  bool _isLoading = false;

  Future<void> _sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(role: 'user', content: userText));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    _history.add({'role': 'user', 'content': userText});

    // Pass current tasks so model knows what exists
    final result = await _aiService.sendMessage(_history, widget.currentTasks);
    final action = result['action'] as String;
    final message = result['message'] as String? ?? '';

    switch (action) {
      case 'add_task':
        widget.onAddTask(result['task'] as String);
        break;

      case 'add_tasks':
        final tasks = result['tasks'] as List<dynamic>;
        print(tasks);
        for (final task in tasks) {
          print(task);
          widget.onAddTask(task as String);
        }
        break;

      case 'complete_task':
        widget.onToggleTask(result['task_id'] as String);
        break;

      case 'delete_task':
        widget.onDeleteTask(result['task_id'] as String);
        break;

      case 'update_task':
        widget.onUpdateTask(
          result['task_id'] as String,
          result['task'] as String,
        );
        break;

      case 'confirm_task':
        // Don't add anything yet — just show the confirmation question
        // The proposed_task is stored in the message bubble context
        // so when user says yes, the history already has it
        break;

      case 'task_declined':
        // Nothing to do — just display the message
        break;

      case 'list_tasks':
        // We handle display in the message bubble below
        break;
    }

    // For list_tasks, build a readable message from current tasks
    String displayMessage = message;
    if (action == 'list_tasks') {
      if (widget.currentTasks.isEmpty) {
        displayMessage = 'You have no tasks yet! Want to add some?';
      } else {
        final taskLines = widget.currentTasks
            .asMap()
            .entries
            .map(
              (e) =>
                  '${e.key + 1}. ${e.value.isCompleted ? "✅" : "⬜"} ${e.value.title}',
            )
            .join('\n');
        displayMessage = 'Here are your tasks:\n\n$taskLines';
      }
    }

    setState(() {
      _messages.add(Message(role: 'assistant', content: displayMessage));
      _isLoading = false;
    });

    _history.add({'role': 'assistant', 'content': displayMessage});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final msg = _messages[i];
              final isUser = msg.role == 'user';
              return Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.deepPurple : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(width: 12),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Thinking...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask your assistant...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () => _sendMessage(_controller.text),
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
