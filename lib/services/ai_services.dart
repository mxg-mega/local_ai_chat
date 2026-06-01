import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String baseUrl = 'http://192.168.0.199:8080';

  final String _systemPrompt = '''
You are a helpful personal assistant. You ONLY respond in valid JSON. Never use markdown. Never add text outside the JSON object.

Classify every user message into one of these actions:

1. If the user wants to add, create, remember, or schedule ONE task:
{"action": "add_task", "task": "short task title", "message": "confirmation message"}

2. If the user wants to add, create, remember, or schedule MULTIPLE tasks:
{"action": "add_tasks", "tasks": ["task 1", "task 2", "task 3"], "message": "confirmation message"}

3. If the user wants to see, list, or check their tasks:
{"action": "list_tasks", "message": "sure, here are your tasks"}

4. Everything else:
{"action": "chat", "message": "your response"}

Examples:
User: "remind me to buy milk" → {"action": "add_task", "task": "Buy milk", "message": "Added! I'll remind you to buy milk."}
User: "I need to sew a hijab, fix my bag and call John" → {"action": "add_tasks", "tasks": ["Sew a hijab", "Fix bag", "Call John"], "message": "Got it! Added 3 tasks for you."}
User: "what tasks do I have?" → {"action": "list_tasks", "message": "Here are your tasks"}
User: "what is the capital of France?" → {"action": "chat", "message": "The capital of France is Paris."}

CRITICAL: Output ONLY a single JSON object. No markdown. No backticks. No extra words. Never output multiple JSON objects.
''';

  String _cleanJson(String raw) {
    String cleaned = raw
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    // Extract only the FIRST complete JSON object
    // This handles cases where the model outputs multiple JSON objects
    int depth = 0;
    int start = -1;
    for (int i = 0; i < cleaned.length; i++) {
      if (cleaned[i] == '{') {
        if (depth == 0) start = i; // mark start of first object
        depth++;
      } else if (cleaned[i] == '}') {
        depth--;
        if (depth == 0 && start != -1) {
          return cleaned.substring(
            start,
            i + 1,
          ); // return first complete object
        }
      }
    }

    return cleaned;
  }

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
        final raw = data['choices'][0]['message']['content'] as String;
        final cleaned = _cleanJson(raw);

        print('Raw: $raw');
        print('Cleaned: $cleaned');

        try {
          return jsonDecode(cleaned);
        } catch (_) {
          return {'action': 'chat', 'message': cleaned};
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
