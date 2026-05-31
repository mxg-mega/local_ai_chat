import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String baseUrl = 'http://192.168.0.199:8080';

  final String _systemPrompt = '''
You are a helpful personal assistant. You ONLY respond in valid JSON. Never use markdown. Never add text outside the JSON object.

Classify every user message into one of these actions:

1. If the user wants to add, create, remember, or schedule anything:
{"action": "add_task", "task": "short task title", "message": "confirmation message"}

2. If the user wants to see, list, or check their tasks:
{"action": "list_tasks", "message": "sure, here are your tasks"}

3. Everything else:
{"action": "chat", "message": "your response"}

Examples:
User: "remind me to buy milk" → {"action": "add_task", "task": "Buy milk", "message": "Added! I'll remind you to buy milk."}
User: "I need to call John tomorrow" → {"action": "add_task", "task": "Call John", "message": "Got it, added a task to call John."}
User: "what tasks do I have?" → {"action": "list_tasks", "message": "Here are your tasks"}
User: "what's the weather like?" → {"action": "chat", "message": "I don't have access to weather data, but..."}

CRITICAL: Output ONLY the JSON object. No markdown. No backticks. No extra words.
''';

  String _cleanJson(String raw) {
    String cleaned = raw
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    // Extract just the JSON object even if model adds surrounding text
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleaned);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
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