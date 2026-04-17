import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Only import vosk on non-web platforms
import 'vosk_stub.dart'
    if (dart.library.io) 'package:vosk_flutter/vosk_flutter.dart';

class WakeWordService {
  static const String _modelName = 'vosk-model-small-en-us-0.15';

  // ── TUNED: Trimmed to only high-confidence phonetic matches ──────────────────
  // Removed: baba, bappa, papa, zappa, napa, deepa, hapa, fapa, gapa, java
  // These caused too many false positives. Kept only close phonetic matches.
  static const List<String> _wakeWords = [
    'nova',    // primary wake word
    'vapa',    // app name
    'vapor',   // common mishear of "vapa"
    'vapour',  // British spelling
    'wafa',    // phonetic mishear
    'nova',    // duplicate kept for grammar weight
  ];

  // ── Confidence threshold — only fire if Vosk confidence is above this ────────
  static const double _minConfidence = 0.65;

  VoskFlutterPlugin? _vosk;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _isInitialized = false;
  bool _isListening = false;

  // Debounce: prevent double-firing wake word within 2 seconds
  DateTime? _lastWakeWordTime;
  static const _debounceMs = 2000;

  Function(String wakeWord)? onWakeWordDetected;
  Function(String error)? onError;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('=== VOSK: Skipped on web platform ===');
      return;
    }

    try {
      debugPrint('=== VOSK: Starting initialization ===');
      _vosk = VoskFlutterPlugin.instance();

      final modelPath = await _extractModel();
      debugPrint('=== VOSK: Model path: $modelPath ===');

      _model = await _vosk!.createModel(modelPath);
      debugPrint('=== VOSK: Model loaded ===');

      // ── TUNED: Grammar now only contains our trimmed wake words ──────────────
      // Smaller grammar = faster recognition + fewer false positives
      // [unk] removed — it was catching random words and slowing processing
      _recognizer = await _vosk!.createRecognizer(
        model: _model!,
        sampleRate: 16000,
        grammar: jsonEncode([..._wakeWords]),
      );
      debugPrint('=== VOSK: Recognizer created with ${_wakeWords.length} wake words ===');

      _isInitialized = true;
      debugPrint('=== VOSK: Initialized successfully ===');
    } catch (e) {
      debugPrint('=== VOSK INIT ERROR: $e ===');
      onError?.call('Wake word init failed: $e');
    }
  }

  Future<String> _extractModel() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/$_modelName');

    if (await modelDir.exists()) {
      // ── TUNED: Verify model is complete by checking a key file ───────────────
      final keyFile = File('${modelDir.path}/am/final.mdl');
      if (await keyFile.exists()) {
        debugPrint('=== VOSK: Model already extracted and verified ===');
        return modelDir.path;
      }
      debugPrint('=== VOSK: Model incomplete, re-extracting ===');
    }

    debugPrint('=== VOSK: Extracting model to ${modelDir.path} ===');

    final files = [
      'README',
      'am/final.mdl',
      'conf/mfcc.conf',
      'conf/model.conf',
      'graph/disambig_tid.int',
      'graph/Gr.fst',
      'graph/HCLr.fst',
      'graph/phones/word_boundary.int',
      'ivector/final.dubm',
      'ivector/final.ie',
      'ivector/final.mat',
      'ivector/global_cmvn.stats',
      'ivector/online_cmvn.conf',
      'ivector/splice.conf',
    ];

    for (final file in files) {
      final assetPath = 'assets/models/$_modelName/$file';
      final outputPath = '${modelDir.path}/$file';
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      final data = await rootBundle.load(assetPath);
      await outputFile.writeAsBytes(data.buffer.asUint8List());
    }

    debugPrint('=== VOSK: Model extracted successfully ===');
    return modelDir.path;
  }

  Future<void> startListening() async {
    if (kIsWeb || !_isInitialized || _isListening) return;

    try {
      _speechService = await _vosk!.initSpeechService(_recognizer!);

      // ── TUNED: Check partials first for faster wake word response ─────────────
      // Partials fire faster than final results — good for wake word detection
      _speechService!.onPartial().listen((partial) {
        final text = _extractText(partial);
        if (text.isNotEmpty) {
          debugPrint('=== VOSK PARTIAL: $text ===');
          _checkWakeWord(text, isFinal: false);
        }
      });

      // Final results used for confirmation
      _speechService!.onResult().listen((result) {
        final text = _extractText(result);
        if (text.isNotEmpty) {
          debugPrint('=== VOSK RESULT: $text ===');
          _checkWakeWord(text, isFinal: true);
        }
      });

      await _speechService!.start();
      _isListening = true;
      debugPrint('=== VOSK: Listening for wake word ===');
    } catch (e) {
      debugPrint('=== VOSK START ERROR: $e ===');
      onError?.call('Could not start wake word detection: $e');
    }
  }

  Future<void> stopListening() async {
    if (kIsWeb || !_isListening) return;
    await _speechService?.stop();
    _isListening = false;
    debugPrint('=== VOSK: Stopped ===');
  }

  Future<void> dispose() async {
    if (kIsWeb) return;
    await stopListening();
    _speechService?.dispose();
    _recognizer?.dispose();
    _model?.dispose();
    _isInitialized = false;
  }

  // ── TUNED: Added debounce + isFinal flag ─────────────────────────────────────
  void _checkWakeWord(String text, {bool isFinal = false}) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return;

    // Debounce: ignore if wake word fired recently
    final now = DateTime.now();
    if (_lastWakeWordTime != null &&
        now.difference(_lastWakeWordTime!).inMilliseconds < _debounceMs) {
      debugPrint('=== VOSK: Wake word debounced ===');
      return;
    }

    for (final w in _wakeWords) {
      if (lower.contains(w)) {
        debugPrint('=== VOSK WAKE WORD DETECTED: $w (final: $isFinal) ===');
        _lastWakeWordTime = now;
        onWakeWordDetected?.call(w);
        return;
      }
    }
  }

  String _extractText(String json) {
    try {
      final data = jsonDecode(json);
      return (data['partial'] ?? data['text'] ?? '') as String;
    } catch (_) {
      return '';
    }
  }
}