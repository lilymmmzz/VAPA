abstract class AIProvider {
  String get name;
  Future<String> sendMessage(String userMessage);
  void clearHistory();
}