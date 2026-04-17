// Stub file for web platform — vosk_flutter uses dart:ffi which is not
// available on web. This stub provides empty implementations so the app
// compiles on web without errors.

class VoskFlutterPlugin {
  static VoskFlutterPlugin instance() => VoskFlutterPlugin._();
  VoskFlutterPlugin._();

  Future<Model> createModel(String path) async => Model(path);

  Future<Recognizer> createRecognizer({
    required Model model,
    required int sampleRate,
    String? grammar,
  }) async =>
      Recognizer();

  Future<SpeechService> initSpeechService(Recognizer recognizer) async =>
      SpeechService();
}

class Model {
  final String path;
  Model(this.path);
  void dispose() {}
}

class Recognizer {
  void dispose() {}
}

class SpeechService {
  Stream<String> onPartial() => const Stream.empty();
  Stream<String> onResult() => const Stream.empty();
  Future<void> start() async {}
  Future<void> stop() async {}
  void dispose() {}
}