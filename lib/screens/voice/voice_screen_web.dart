import 'dart:js_interop';

// ─── Speech Recognition ───────────────────────────────────────────────────────
@JS('startSpeechRecognition')
external JSPromise _startSpeechRecognition(JSFunction onResult, JSFunction onError);

@JS('stopSpeechRecognition')
external void _stopSpeechRecognition(JSAny? handle);

@JS('pauseSpeechRecognition')
external void _pauseSpeechRecognition();

@JS('resumeSpeechRecognition')
external void _resumeSpeechRecognition();

// ─── SPEED FIX: Native Browser TTS ───────────────────────────────────────────
// Bypasses flutter_tts Dart bridge — calls window.speechSynthesis directly.
// This eliminates the biggest TTS delay on web.
@JS('nativeSpeak')
external void _nativeSpeak(JSString text, JSNumber rate, JSNumber pitch, JSFunction? onDone);

@JS('nativeStop')
external void _nativeStop();

// ─── Public API used by voice_screen.dart ────────────────────────────────────

dynamic startWebSpeech(
  Function(String, bool) onResult,
  Function(String) onError,
) {
  _startSpeechRecognition(
    ((JSString transcript, JSBoolean isFinal) {
      onResult(transcript.toDart, isFinal.toDart);
    }).toJS,
    ((JSString error) {
      onError(error.toDart);
    }).toJS,
  );
  // Return a non-null sentinel so voice_screen knows recognition started
  return Object();
}

void stopWebSpeech(dynamic handle) {
  _stopSpeechRecognition(null);
}

/// Call this BEFORE speaking so the mic does not pick up Nova's voice
void pauseWebSpeech() {
  _pauseSpeechRecognition();
}

/// Call this AFTER TTS finishes to resume listening immediately
void resumeWebSpeech() {
  _resumeSpeechRecognition();
}

/// Speak text using native browser speechSynthesis (much faster than flutter_tts on web)
/// [onDone] is called when speaking finishes so voice_screen can resume listening
void webSpeak(String text, {double rate = 1.15, double pitch = 1.0, Function? onDone}) {
  pauseWebSpeech();
  _nativeSpeak(
    text.toJS,
    rate.toJS,
    pitch.toJS,
    onDone != null ? (() { onDone(); }).toJS : null,
  );
}

/// Stop any ongoing native TTS immediately
void webStopSpeaking() {
  _nativeStop();
}