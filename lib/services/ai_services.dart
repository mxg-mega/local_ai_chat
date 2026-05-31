import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  // static const String baseUrl = 'http://localhost:8080';
  final String baseUrl = 'http://192.168.0.199:8080';

  final String _systemPrompt = '''
You are a helpful personal assistant that helps with tasks and organization.

when the users asks you to add a task, create or remember a task you must responds in this format:
{"action": "add_task", "task": "[TASK TITLE HERE]", "message": "[YOU FRIENDLY CONFIRMATION HERE]", "description": "[OPTIONAL TASK DESCRIPTION HERE]"}

when the user asks you to list tasks, show tasks or what are my tasks you must responds in this format:
{"action": "list_tasks"}

for all other messages, respond in this exact json format:
{"action": "chat", "message": "[YOUR RESPONSE HERE]"}

IMPORTANT: Always respond with valid JSON only. No extra text outside the JSON.

''';
  Future<Map<String, dynamic>> sendMessage(
    List<Map<String, String>> history,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...history,
          ],
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        final refactoredContent = content
            .replaceAll(RegExp(r'```'), ' ')
            .replaceFirst(r'json', ' ')
            .trim();

        // Try to parse the AI's response as JSON
        // If it fails, treat it as a plain chat message
        try {
          print(content);
          print(refactoredContent);
          return jsonDecode(refactoredContent);
        } catch (_) {
          return {
            'action': 'chat',
            'message': jsonDecode(refactoredContent)['message'],
          };
        }
      }
      return {
        'action': 'chat',
        'message': '⚠️ Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'action': 'chat',
        'message': '⚠️ Could not reach server. Is llama-server running?',
      };
    }
  }
}
