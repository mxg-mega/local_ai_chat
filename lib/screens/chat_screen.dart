import 'package:flutter/material.dart';
import 'package:local_ai_chat/services/ai_services.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  // We pass a callback so chat can trigger task creation in the parent
  final Function(String taskTitle) onAddTask;

  const ChatScreen({super.key, required this.onAddTask});

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

    // Add to API history
    _history.add({'role': 'user', 'content': userText});

    final result = await _aiService.sendMessage(_history);
    final action = result['action'] as String;
    final message = result['message'] as String? ?? '';

    if (action == 'add_task') {
      // Single task
      final taskTitle = result['task'] as String;
      widget.onAddTask(taskTitle);
    } else if (action == 'add_tasks') {
      // Multiple tasks — iterate and add each one
      final tasks = result['tasks'] as List<dynamic>;
      print(tasks);
      for (final task in tasks) {
        widget.onAddTask(task as String);
      }
    }

    setState(() {
      _messages.add(Message(role: 'assistant', content: message));
      _isLoading = false;
    });

    // Add assistant reply to history for context in next message
    _history.add({'role': 'assistant', 'content': message});
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
