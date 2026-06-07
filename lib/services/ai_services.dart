import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class AiService {
  // final String baseUrl = 'http://192.168.0.199:8080';
  final String baseUrl = 'http://0.0.0.0:8080';

  String _buildSystemPrompt(List<Task> tasks) {
    final taskContext = tasks.isEmpty
        ? 'No tasks.'
        : tasks
              .asMap()
              .entries
              .map(
                (e) =>
                    '${e.key + 1}.[${e.value.id}] ${e.value.title}(${e.value.isCompleted ? "done" : "pending"})',
              )
              .join('\n');

    return '''
You are a JSON-only assistant. Reply ONLY with one JSON object, no markdown.

TASKS:
$taskContext

ACTIONS:
- add_task: {"action":"add_task","task":"title","message":"reply"}
- add_tasks: {"action":"add_tasks","tasks":["t1","t2"],"message":"reply"}
- complete_task: {"action":"complete_task","task_id":"id","message":"reply"}
- delete_task: {"action":"delete_task","task_id":"id","message":"reply"}
- update_task: {"action":"update_task","task_id":"id","task":"title","message":"reply"}
- list_tasks: {"action":"list_tasks","message":"reply"}
- confirm_task: {"action":"confirm_task","proposed_task":"title","message":"question"}
- task_declined: {"action":"task_declined","message":"reply"}
- chat: {"action":"chat","message":"reply"}

Add task only if explicitly requested or confirmed. Ask confirm_task if ambiguous.
''';
  }

  String _cleanJson(String raw) {
    // With grammar enforcement, this is mostly just a safety trim
    return raw.trim();
  }

  // String _cleanJson(String raw) {
  //   String cleaned = raw
  //       .replaceAll(RegExp(r'```json', caseSensitive: false), '')
  //       .replaceAll('```', '')
  //       .trim();

  //   int depth = 0;
  //   int start = -1;
  //   for (int i = 0; i < cleaned.length; i++) {
  //     if (cleaned[i] == '{') {
  //       if (depth == 0) start = i;
  //       depth++;
  //     } else if (cleaned[i] == '}') {
  //       depth--;
  //       if (depth == 0 && start != -1) {
  //         return cleaned.substring(start, i + 1);
  //       }
  //     }
  //   }
  //   return cleaned;
  // }

  Future<Map<String, dynamic>> sendMessage(
    List<Map<String, String>> history,
    List<Task> currentTasks, // 👈 new parameter
  ) async {
    try {
      final response = await http.post(
        // commented out if using ollama
        Uri.parse('$baseUrl/v1/chat/completions'),
        // Uri.parse('$baseUrl/api/chat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'messages': [
            {'role': 'system', 'content': _buildSystemPrompt(currentTasks)},
            ...history,
          ],

          'max_tokens': 1024,
        }),
      );

      // print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print('Decoded API response: $data');
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

      print('Error: ${response.statusCode} - ${response.body}');

      return {
        'action': 'chat',
        'message': '⚠️ Server error: ${response.statusCode}',
      };
    } catch (e) {
      print('Response MainError: ${e.toString()}');
      return {
        'action': 'chat',
        'message': '⚠️ Could not reach server. Is llama-server running?',
      };
    }
  }
}
