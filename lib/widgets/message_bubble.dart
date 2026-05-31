import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}