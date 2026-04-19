import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class GeminiProvider implements AIProvider {
  @override
  String get name => 'Groq';

static const String _apiKey = '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';
static const String _apiUrl = 'https://integrate.api.nvidia.com/v1/chat/completions';
static const String _model = 'meta/llama-3.3-70b-instruct';

  final String systemPrompt;
  final List<Map<String, dynamic>> _history = [];

  GeminiProvider({
    this.systemPrompt =
        'You are VAPA, a helpful voice-activated personal assistant. '
        'Keep responses short and conversational — under 3 sentences — '
        'since they will be spoken aloud. Be friendly, clear, and direct.',
  });

  @override
  Future<String> sendMessage(String userMessage) async {
    _history.add({'role': 'user', 'content': userMessage});

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ..._history,
    ];

    try {
      print('=== GROQ CALLING API ===');
      print('=== MESSAGE: $userMessage ===');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 300,
          'temperature': 0.9,
        }),
      ).timeout(const Duration(seconds: 20));

      print('=== GROQ STATUS: ${response.statusCode} ===');
      print('=== GROQ BODY: ${response.body} ===');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;

        _history.add({'role': 'assistant', 'content': reply.trim()});
        if (_history.length > 20) _history.removeRange(0, 2);

        print('=== GROQ REPLY: $reply ===');
        return reply.trim();

      } else {
        print('=== GROQ ERROR: ${response.statusCode} ${response.body} ===');
        return "Sorry, I couldn't connect right now. Status: ${response.statusCode}";
      }

    } catch (e) {
      print('=== GROQ EXCEPTION: $e ===');
      return "I'm having trouble reaching the server. Check your connection.";
    }
  }

  @override
  void clearHistory() => _history.clear();
}
