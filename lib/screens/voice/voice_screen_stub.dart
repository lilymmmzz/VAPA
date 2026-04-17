// Stub file for non-web platforms (mobile/desktop)
// Must mirror all functions in voice_screen_web.dart

dynamic startWebSpeech(Function(String, bool) onResult, Function(String) onError) {
  return null;
}

void stopWebSpeech(dynamic recognition) {}

void pauseWebSpeech() {}

void resumeWebSpeech() {}

void webSpeak(String text, {double rate = 1.15, double pitch = 1.0, Function? onDone}) {
  // No-op on mobile — flutter_tts handles speaking instead
  onDone?.call();
}

void webStopSpeaking() {}