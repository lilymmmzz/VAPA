import 'ai_provider.dart';
import 'gemini_provider.dart';

// Single model — Groq via GeminiProvider
enum AIModel { gemini, claude }

class AiService {
  final GeminiProvider _groq = GeminiProvider();

  AIModel get currentModel => AIModel.gemini;
  String get currentModelName => 'Groq';

  void switchModel(AIModel model) {
    // Single provider — nothing to switch
    _groq.clearHistory();
  }

  Future<String> sendMessage(String userMessage, {bool autoRoute = true}) async {
    try {
      return await _groq.sendMessage(userMessage);
    } catch (e) {
      print('=== AI SERVICE ERROR: $e ===');
      return "Sorry, I couldn't process that. Please try again.";
    }
  }

  void clearHistory() => _groq.clearHistory();
}
