import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/ai_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/mood_provider.dart';
import 'voice_screen_web.dart' if (dart.library.io) 'voice_screen_stub.dart';

enum _ConvState {
  idle, awaitingCommand, noteAskTitle, noteAskContent,
  reminderAskTitle, reminderAskDate, awaitingAnythingElse, stopped,
}

// ── Navigation callback — set by HomeScreen so VoiceScreen can switch tabs ───
// 0 = Notes, 1 = Reminders, 2 = Mood, 3 = Profile
typedef NavigateCallback = void Function(int tabIndex);

class VoiceScreen extends StatefulWidget {
  final NavigateCallback? onNavigate;
  const VoiceScreen({super.key, this.onNavigate});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final AiService _aiService = AiService();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _speechAvailable = false;
  String _transcribedText = '';
  String _statusMessage = 'Initializing...';
  final List<Map<String, dynamic>> _conversation = [];
  dynamic _webRecognition;

  _ConvState _convState = _ConvState.idle;
  String _pendingNoteTitle = '';
  String _pendingNoteContent = '';
  String _pendingReminderTitle = '';
  String _pendingReminderDate = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _wakeWords = [
    'hey nova', 'nova', 'hey vapa', 'vapa', 'hey vapor', 'vapor',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(_pulseController);
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    if (kIsWeb) {
      setState(() => _statusMessage = 'Say "Hey Nova" to begin');
      return;
    }
    try {
      _speechAvailable = await _speechToText.initialize(
        onError: (e) {
          if (e.permanent == false && !_isProcessing && !_isSpeaking &&
              _convState != _ConvState.stopped && _convState != _ConvState.idle) {
            Future.delayed(const Duration(milliseconds: 300), _startListening);
          }
        },
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && _isListening && !_isProcessing && !_isSpeaking) {
            if (mounted) {
              setState(() {
                _isListening = false;
                _transcribedText = '';
                if (_convState == _ConvState.idle || _convState == _ConvState.stopped) {
                  _statusMessage = 'Say "Hey Nova" to begin';
                }
              });
              if (_convState == _ConvState.idle) {
                Future.delayed(const Duration(milliseconds: 200), _startListening);
              }
            }
          }
        },
      );
      setState(() => _statusMessage = _speechAvailable
          ? 'Say "Hey Nova" to begin'
          : 'Microphone not available');
      if (_speechAvailable) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _greetAndListen());
      }
    } catch (e) {
      setState(() => _statusMessage = 'Speech init failed');
    }
  }

  Future<void> _initTts() async {
    if (kIsWeb) return;
    await _flutterTts.setLanguage('en-GB');
    // ── TUNED: 0.45 = natural calm British male pace ──────────────────────────
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(0.85);
    try {
      final voices = await _flutterTts.getVoices as List<dynamic>;
      final male = voices.firstWhere(
        (v) =>
            (v['locale'].toString().contains('en-GB') ||
             v['locale'].toString().contains('en_GB')) &&
            (v['name'].toString().toLowerCase().contains('male') ||
             v['name'].toString().toLowerCase().contains('daniel') ||
             v['name'].toString().toLowerCase().contains('oliver') ||
             v['name'].toString().toLowerCase().contains('george')),
        orElse: () => null,
      );
      if (male != null) {
        await _flutterTts.setVoice({'name': male['name'], 'locale': male['locale']});
      } else {
        await _flutterTts.setLanguage('en-GB');
      }
    } catch (_) {}
  }

  Future<void> _greetAndListen() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = auth.user?.email ?? '';
    String name = 'there';
    if (email.isNotEmpty) {
      final raw = email.split('@')[0].split('.')[0];
      name = raw[0].toUpperCase() + raw.substring(1);
    }
    // ── TUNED: Warmer, friendlier greeting ───────────────────────────────────
    final greeting = 'Hello $name, I\'m Nova. How can I help you today?';
    _novaSays(greeting);
    await _speak(greeting);
    _startListening();
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;

    if (kIsWeb) {
      setState(() { _isListening = false; _isSpeaking = true; });
      final completer = Completer<void>();
      webSpeak(
        text,
        // ── TUNED: 0.88 = slightly slower, more natural British pace ─────────
        rate: 0.88,
        pitch: 0.85,
        onDone: () { if (!completer.isCompleted) completer.complete(); },
      );
      await completer.future.timeout(const Duration(seconds: 15), onTimeout: () {});
      if (mounted) {
        setState(() => _isSpeaking = false);
        resumeWebSpeech();
      }
      return;
    }

    await _speechToText.stop();
    setState(() { _isListening = false; _isSpeaking = true; });
    final completer = Completer<void>();
    _flutterTts.setCompletionHandler(() { if (!completer.isCompleted) completer.complete(); });
    _flutterTts.setCancelHandler(() { if (!completer.isCompleted) completer.complete(); });
    _flutterTts.setErrorHandler((msg) { if (!completer.isCompleted) completer.complete(); });
    await _flutterTts.speak(text);
    await completer.future.timeout(const Duration(seconds: 12), onTimeout: () {});
    if (mounted) setState(() => _isSpeaking = false);
  }

  // ── Add a text message bubble ─────────────────────────────────────────────
  void _novaSays(String text) {
    if (!mounted) return;
    setState(() => _conversation.insert(0, {'role': 'vapa', 'type': 'text', 'text': text}));
    _scrollToBottom();
  }

  void _userSaid(String text) {
    if (!mounted) return;
    setState(() => _conversation.insert(0, {'role': 'user', 'type': 'text', 'text': text}));
    _scrollToBottom();
  }

  // ── Add a visual list card bubble ─────────────────────────────────────────
  void _novaShowsList(String header, List<Map<String, String>> items, IconData icon) {
    if (!mounted) return;
    setState(() => _conversation.insert(0, {
      'role': 'vapa',
      'type': 'list',
      'header': header,
      'items': items,
      'icon': icon.codePoint.toString(),
      'iconFont': icon.fontFamily ?? 'MaterialIcons',
    }));
    _scrollToBottom();
  }

  Future<void> _startListening() async {
    if (!mounted || _isListening || _isProcessing || _isSpeaking) return;
    if (_convState == _ConvState.stopped) return;

    if (kIsWeb) {
      if (_webRecognition == null) {
        setState(() {
          _isListening = true;
          _transcribedText = '';
          _statusMessage = _convState == _ConvState.idle
              ? 'Listening... say "Hey Nova"'
              : 'Listening...';
        });
        _webRecognition = startWebSpeech(
          (transcript, isFinal) {
            if (!mounted) return;
            setState(() => _transcribedText = transcript);
            if (isFinal && !_isSpeaking) _routeSpeech(transcript);
          },
          (error) {
            if (mounted && error != 'no-speech') {
              setState(() { _isListening = false; });
            }
          },
        );
      } else {
        setState(() {
          _isListening = true;
          _statusMessage = _convState == _ConvState.idle
              ? 'Listening... say "Hey Nova"'
              : 'Listening...';
        });
      }
      return;
    }

    if (!_speechAvailable) { await _initSpeech(); if (!_speechAvailable) return; }
    setState(() {
      _isListening = true;
      _transcribedText = '';
      _statusMessage = _convState == _ConvState.idle
          ? 'Listening... say "Hey Nova"'
          : 'Listening...';
    });
    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          setState(() => _transcribedText = words);
          if (result.finalResult && words.isNotEmpty && !_isSpeaking && !_isProcessing) {
            _routeSpeech(words);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(milliseconds: 2500),
        partialResults: true,
        localeId: 'en_US',
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      );
    } catch (e) {
      if (mounted) setState(() { _isListening = false; });
    }
  }

  Future<void> _stopListening() async {
    if (kIsWeb) {
      stopWebSpeech(_webRecognition);
      _webRecognition = null;
    } else {
      await _speechToText.stop();
    }
    if (mounted) {
      setState(() {
        _isListening = false;
        _convState = _ConvState.stopped;
        _statusMessage = 'Tap mic to listen';
      });
    }
  }

  void _routeSpeech(String raw) {
    if (!mounted || _isSpeaking || _isProcessing) return;
    switch (_convState) {
      case _ConvState.idle: _handleWakeWord(raw); break;
      case _ConvState.awaitingCommand:
        setState(() => _convState = _ConvState.idle);
        _processCommand(raw);
        break;
      case _ConvState.noteAskTitle: _handleNoteTitle(raw); break;
      case _ConvState.noteAskContent: _handleNoteContent(raw); break;
      case _ConvState.reminderAskTitle: _handleReminderTitle(raw); break;
      case _ConvState.reminderAskDate: _handleReminderDate(raw); break;
      case _ConvState.awaitingAnythingElse: _handleAnythingElse(raw); break;
      case _ConvState.stopped: break;
    }
  }

  String? _extractWakeWord(String input) {
    final lower = input.toLowerCase().trim();
    for (final w in _wakeWords) { if (lower.contains(w)) return w; }
    return null;
  }

  String _extractCommand(String input, String wakeWord) {
    final lower = input.toLowerCase();
    final idx = lower.indexOf(wakeWord);
    if (idx == -1) return '';
    return lower.substring(idx + wakeWord.length).trim()
        .replaceFirst(RegExp(r'^[,\.\s]+'), '').trim();
  }

  Future<void> _handleWakeWord(String raw) async {
    final matched = _extractWakeWord(raw);
    if (matched == null) return;
    final cleaned = _extractCommand(raw, matched);
    if (cleaned.isEmpty) {
      setState(() => _convState = _ConvState.awaitingCommand);
      if (!kIsWeb) await _speechToText.stop();
      setState(() => _isListening = false);
      await _speak('Yes, how can I help?');
      await _startListening();
    } else {
      await _processCommand(cleaned);
    }
  }

  // ── Navigation intent classifier ──────────────────────────────────────────
  int? _classifyNavigation(String command) {
    final c = command.toLowerCase();
    final isNavigate = c.contains('take me') || c.contains('go to') ||
        c.contains('open') || c.contains('show me') || c.contains('navigate') ||
        c.contains('i want to see') || c.contains('switch to');
    if (!isNavigate) return null;
    if (c.contains('note')) return 0;
    if (c.contains('reminder') || c.contains('alarm')) return 1;
    if (c.contains('mood') || c.contains('feeling')) return 2;
    if (c.contains('profile') || c.contains('settings')) return 3;
    return null;
  }

  String _classifyIntent(String command) {
    final c = command.toLowerCase();
    // Navigation first
    if (_classifyNavigation(c) != null) return 'NAVIGATE';
    if ((c.contains('delete') || c.contains('remove') || c.contains('erase')) && c.contains('note')) return 'DELETE_NOTE';
    if ((c.contains('delete') || c.contains('remove') || c.contains('cancel')) && c.contains('reminder')) return 'DELETE_REMINDER';
    if ((c.contains('done') || c.contains('complete') || c.contains('finish') || c.contains('mark')) && c.contains('reminder')) return 'COMPLETE_REMINDER';
    if ((c.contains('create') || c.contains('add') || c.contains('save') || c.contains('write') || c.contains('new') || c.contains('make')) && c.contains('note')) return 'CREATE_NOTE';
    if (c.contains('remind') || c.contains('reminder') || ((c.contains('set') || c.contains('create') || c.contains('add')) && (c.contains('alarm') || c.contains('alert')))) return 'CREATE_REMINDER';
    if ((c.contains('list') || c.contains('show') || c.contains('what') || c.contains('read') || c.contains('my')) && c.contains('note')) return 'READ_NOTES';
    if ((c.contains('list') || c.contains('show') || c.contains('what') || c.contains('read') || c.contains('my')) && c.contains('reminder')) return 'READ_REMINDERS';
    if (c.contains('mood') || c.contains('feeling') || c.contains('feel') || c.contains('log my')) return 'LOG_MOOD';
    if (c.contains('help') || c.contains('what can you')) return 'HELP';
    return 'AI_QUERY';
  }

  Future<void> _startNoteFlow() async {
    setState(() => _convState = _ConvState.noteAskTitle);
    const q = 'Of course! What would you like to call this note?';
    _novaSays(q); await _speak(q); await _startListening();
  }

  Future<void> _handleNoteTitle(String raw) async {
    _userSaid(raw);
    _pendingNoteTitle = raw.trim().isEmpty ? 'Voice Note' : raw.trim();
    setState(() => _convState = _ConvState.noteAskContent);
    const q = 'Great! And what should the note say?';
    _novaSays(q); await _speak(q); await _startListening();
  }

  Future<void> _handleNoteContent(String raw) async {
    _userSaid(raw);
    _pendingNoteContent = raw.trim().isEmpty ? 'Created via voice' : raw.trim();
    setState(() { _convState = _ConvState.idle; _isProcessing = true; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final notes = Provider.of<NotesProvider>(context, listen: false);
      await notes.createNote(auth.user?.uid ?? '', _pendingNoteTitle, _pendingNoteContent);
    } catch (e) { print('=== CREATE NOTE ERROR: $e ==='); }
    if (mounted) setState(() => _isProcessing = false);
    await _askAnythingElse('Done! I\'ve saved your note called "$_pendingNoteTitle".');
  }

  Future<void> _startReminderFlow() async {
    setState(() => _convState = _ConvState.reminderAskTitle);
    const q = 'Sure! What would you like me to remind you about?';
    _novaSays(q); await _speak(q); await _startListening();
  }

  Future<void> _handleReminderTitle(String raw) async {
    _userSaid(raw);
    _pendingReminderTitle = raw.trim().isEmpty ? 'Voice Reminder' : raw.trim();
    setState(() => _convState = _ConvState.reminderAskDate);
    const q = 'Got it. When would you like me to remind you?';
    _novaSays(q); await _speak(q); await _startListening();
  }

  Future<void> _handleReminderDate(String raw) async {
    _userSaid(raw);
    _pendingReminderDate = raw.trim();
    setState(() { _convState = _ConvState.idle; _isProcessing = true; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final reminders = Provider.of<RemindersProvider>(context, listen: false);
      DateTime scheduled = DateTime.now().add(const Duration(hours: 1));
      final parsed = await _parseDateTime(_pendingReminderDate);
      if (parsed != null) scheduled = parsed;
      await reminders.createReminder(
          auth.user?.uid ?? '', _pendingReminderTitle, 'Created via voice', scheduled);
      final dateStr = '${scheduled.day}/${scheduled.month}/${scheduled.year} at '
          '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}';
      if (mounted) setState(() => _isProcessing = false);
      await _askAnythingElse('Perfect! I\'ve set your reminder for $dateStr.');
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      await _askAnythingElse('Your reminder has been saved.');
    }
  }

  Future<void> _askAnythingElse(String confirmMsg) async {
    setState(() => _convState = _ConvState.awaitingAnythingElse);
    final msg = '$confirmMsg Is there anything else I can help you with?';
    _novaSays(msg); await _speak(msg); await _startListening();
  }

  Future<void> _handleAnythingElse(String raw) async {
    _userSaid(raw);
    final lower = raw.toLowerCase();
    final trimmed = lower.trim().replaceAll(RegExp(r'[^a-z ]'), '');
    final isYes = trimmed == 'yes' || trimmed == 'yeah' || trimmed == 'sure' ||
        trimmed == 'yep' || trimmed == 'okay' || trimmed == 'ok' ||
        trimmed.startsWith('yes ') || lower.contains('go ahead');
    final isNo = trimmed == 'no' || trimmed == 'nope' || trimmed == 'nah' ||
        trimmed == 'no thank you' || trimmed == 'no thanks' ||
        trimmed == 'thats all' || trimmed == 'thats it' ||
        trimmed == 'im good' || trimmed == 'im okay' ||
        (trimmed.startsWith('no ') &&
            !trimmed.contains('note') &&
            !trimmed.contains('now'));

    if (isYes) {
      setState(() => _convState = _ConvState.awaitingCommand);
      const q = 'Of course! What would you like to do?';
      _novaSays(q); await _speak(q); await _startListening();
    } else if (isNo) {
      if (!kIsWeb) await _speechToText.stop();
      setState(() {
        _convState = _ConvState.stopped;
        _isListening = false;
        _statusMessage = 'Tap mic to listen';
      });
      const bye = 'No problem! Just tap the microphone whenever you need me.';
      _novaSays(bye);
      await _speak(bye);
      if (kIsWeb) { stopWebSpeech(_webRecognition); _webRecognition = null; }
      if (mounted) setState(() { _isListening = false; _statusMessage = 'Tap mic to listen'; });
    } else {
      setState(() => _convState = _ConvState.idle);
      await _processCommand(raw);
    }
  }

  Future<DateTime?> _parseDateTime(String command) async {
    try {
      final now = DateTime.now();
      final reply = await _aiService.sendMessage(
        'Extract date and time from: "$command". Today is ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}. Reply ONLY: YYYY-MM-DD HH:mm. No time=09:00. No date=tomorrow.',
        autoRoute: false,
      );
      return DateTime.tryParse(reply.trim());
    } catch (_) { return null; }
  }

  String? _findNoteId(List notes, String hint) {
    final h = hint.toLowerCase();
    for (final n in notes) { if (n.title.toLowerCase() == h) return n.id; }
    for (final n in notes) {
      if (n.title.toLowerCase().contains(h) || h.contains(n.title.toLowerCase())) return n.id;
    }
    return null;
  }

  String? _findReminderId(List reminders, String hint) {
    final h = hint.toLowerCase();
    for (final r in reminders) { if (r.title.toLowerCase() == h) return r.id; }
    for (final r in reminders) {
      if (r.title.toLowerCase().contains(h) || h.contains(r.title.toLowerCase())) return r.id;
    }
    return null;
  }

  // ── Navigate to a tab and close the Nova sheet ────────────────────────────
  void _navigateTo(int tabIndex) {
    final names = ['Notes', 'Reminders', 'Mood', 'Profile'];
    final name = names[tabIndex];
    if (widget.onNavigate != null) {
      widget.onNavigate!(tabIndex);
      // Close the Nova bottom sheet
      if (mounted) Navigator.of(context).maybePop();
    } else {
      // Fallback if no callback — just confirm
      _novaSays('Opening $name for you.');
    }
  }

  Future<void> _processCommand(String command) async {
    if (!mounted) return;
    if (!kIsWeb) await _speechToText.stop();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notes = Provider.of<NotesProvider>(context, listen: false);
    final reminders = Provider.of<RemindersProvider>(context, listen: false);
    final mood = Provider.of<MoodProvider>(context, listen: false);
    final userId = auth.user?.uid ?? '';

    setState(() { _isProcessing = true; _isListening = false; _transcribedText = ''; });
    _userSaid(command);
    final intent = _classifyIntent(command);

    try {
      // ── NAVIGATION ────────────────────────────────────────────────────────
      if (intent == 'NAVIGATE') {
        final tabIndex = _classifyNavigation(command);
        if (tabIndex != null) {
          final names = ['Notes', 'Reminders', 'Mood', 'Profile'];
          final spokenName = names[tabIndex];
          if (mounted) setState(() => _isProcessing = false);
          final msg = 'Sure! Taking you to $spokenName right away.';
          _novaSays(msg);
          await _speak(msg);
          _navigateTo(tabIndex);
          return;
        }
      }

      if (intent == 'CREATE_NOTE') { setState(() => _isProcessing = false); await _startNoteFlow(); return; }
      if (intent == 'CREATE_REMINDER') { setState(() => _isProcessing = false); await _startReminderFlow(); return; }

      String response = '';

      // ── READ NOTES — show visual list ─────────────────────────────────────
      if (intent == 'READ_NOTES') {
        if (mounted) setState(() => _isProcessing = false);
        if (notes.notes.isEmpty) {
          response = 'You don\'t have any notes yet. Would you like to create one?';
        } else {
          final count = notes.notes.length;
          response = 'You have $count note${count == 1 ? '' : 's'}. Here they are:';
          _novaSays(response);
          await _speak(response);
          // Show visual list card
          _novaShowsList(
            'Your Notes',
            notes.notes.take(10).map((n) => {
              'title': n.title,
              'subtitle': n.content.length > 50
                  ? '${n.content.substring(0, 50)}...'
                  : n.content,
            }).toList(),
            Icons.sticky_note_2,
          );
          await _askAnythingElse('');
          return;
        }

      // ── READ REMINDERS — show visual list ─────────────────────────────────
      } else if (intent == 'READ_REMINDERS') {
        if (mounted) setState(() => _isProcessing = false);
        final upcoming = reminders.reminders.where((r) => !r.isCompleted).toList();
        if (upcoming.isEmpty) {
          response = 'You don\'t have any upcoming reminders.';
        } else {
          response = 'You have ${upcoming.length} upcoming reminder${upcoming.length == 1 ? '' : 's'}. Here they are:';
          _novaSays(response);
          await _speak(response);
          // Show visual list card
          _novaShowsList(
            'Your Reminders',
            upcoming.take(10).map((r) => {
              'title': r.title,
              'subtitle': '${r.scheduledDateTime.day}/${r.scheduledDateTime.month}/${r.scheduledDateTime.year} '
                  'at ${r.scheduledDateTime.hour.toString().padLeft(2, '0')}:${r.scheduledDateTime.minute.toString().padLeft(2, '0')}',
            }).toList(),
            Icons.alarm,
          );
          await _askAnythingElse('');
          return;
        }

      } else if (intent == 'DELETE_NOTE') {
        final titleHint = await _aiService.sendMessage(
            'From: "$command" extract the note name to delete. Reply with ONLY the name.', autoRoute: false);
        final noteId = _findNoteId(notes.notes, titleHint.trim());
        if (noteId != null) {
          final name = notes.notes.firstWhere((n) => n.id == noteId).title;
          await notes.deleteNote(userId, noteId);
          response = 'Done! I\'ve deleted the note called "$name".';
        } else {
          response = notes.notes.isEmpty
              ? 'You don\'t have any notes to delete.'
              : 'I couldn\'t find that note. Your notes are: ${notes.notes.map((n) => n.title).join(', ')}.';
        }
      } else if (intent == 'DELETE_REMINDER') {
        final titleHint = await _aiService.sendMessage(
            'From: "$command" extract the reminder name to delete. Reply with ONLY the name.', autoRoute: false);
        final reminderId = _findReminderId(reminders.reminders, titleHint.trim());
        if (reminderId != null) {
          final name = reminders.reminders.firstWhere((r) => r.id == reminderId).title;
          await reminders.deleteReminder(userId, reminderId);
          response = 'Done! I\'ve removed the reminder "$name".';
        } else { response = 'I couldn\'t find that reminder.'; }
      } else if (intent == 'COMPLETE_REMINDER') {
        final titleHint = await _aiService.sendMessage(
            'From: "$command" extract the reminder name to mark done. Reply with ONLY the name.', autoRoute: false);
        final reminderId = _findReminderId(reminders.reminders, titleHint.trim());
        if (reminderId != null) {
          final name = reminders.reminders.firstWhere((r) => r.id == reminderId).title;
          await reminders.completeReminder(userId, reminderId);
          response = 'Great! I\'ve marked "$name" as done.';
        } else { response = 'I couldn\'t find that reminder.'; }
      } else if (intent == 'LOG_MOOD') {
        final moodReply = await _aiService.sendMessage(
            'From: "$command" identify mood: happy, sad, anxious, calm, excited, tired, angry, neutral. Reply ONLY that word.', autoRoute: false);
        final detectedMood = moodReply.trim().toLowerCase();
        await mood.logMoodFromVoice(userId, detectedMood, command);
        response = 'Got it! I\'ve logged your mood as $detectedMood.';
      } else if (intent == 'HELP') {
        response = 'I can help you create notes, set reminders, log your mood, answer questions, '
            'or take you to any screen. Just say "Hey Nova" followed by what you need.';
      } else {
        setState(() => _statusMessage = 'Thinking...');
        response = await _aiService.sendMessage(command);
      }

      if (mounted) setState(() => _isProcessing = false);
      await _askAnythingElse(response);
    } catch (e) {
      print('=== PROCESS ERROR: $e ===');
      if (mounted) setState(() => _isProcessing = false);
      const err = 'I\'m sorry, something went wrong. Please try again.';
      _novaSays(err);
      await _speak(err);
      setState(() => _convState = _ConvState.idle);
      _startListening();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    if (kIsWeb) { webStopSpeaking(); stopWebSpeech(_webRecognition); }
    _speechToText.stop();
    _flutterTts.stop();
    _textController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActivelyListening = _isListening;
    return Scaffold(
      backgroundColor: const Color(0xFF13131F),
      body: Column(
        children: [
          Expanded(
            child: _conversation.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.record_voice_over, size: 64, color: cs.primary.withValues(alpha: 0.35)),
                    const SizedBox(height: 16),
                    Text('Say "Hey Nova" to get started',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  ]))
                : ListView.builder(
                    controller: _scrollController, reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _conversation.length,
                    itemBuilder: (context, i) {
                      final msg = _conversation[i];
                      // ── Render list card or text bubble ──────────────────
                      if (msg['type'] == 'list') {
                        return _ListCard(
                          header: msg['header'] as String,
                          items: (msg['items'] as List).cast<Map<String, String>>(),
                          icon: IconData(
                            int.parse(msg['icon'] as String),
                            fontFamily: msg['iconFont'] as String,
                          ),
                          colorScheme: cs,
                        );
                      }
                      return _ConversationBubble(
                          text: msg['text'] as String,
                          isUser: msg['role'] == 'user',
                          colorScheme: cs);
                    }),
          ),
          if (_transcribedText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: cs.secondary.withValues(alpha: 0.15),
              child: Text(_transcribedText,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  textAlign: TextAlign.center),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_statusMessage, key: ValueKey(_statusMessage),
                    style: TextStyle(fontSize: 13,
                        color: _isProcessing ? cs.tertiary
                            : isActivelyListening ? cs.primary
                            : Colors.grey[600],
                        fontWeight: isActivelyListening ? FontWeight.w500 : FontWeight.normal)),
              ),
              const SizedBox(height: 14),
              ScaleTransition(
                scale: isActivelyListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: GestureDetector(
                  onTap: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      setState(() => _convState = _ConvState.idle);
                      _startListening();
                    }
                  },
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing ? Colors.grey[800]
                          : isActivelyListening ? Colors.red
                          : cs.primary,
                      boxShadow: [BoxShadow(
                          color: (isActivelyListening ? Colors.red : cs.primary).withValues(alpha: 0.35),
                          blurRadius: _isListening ? 28 : 8,
                          spreadRadius: _isListening ? 6 : 2)],
                    ),
                    child: Icon(
                        _isProcessing ? Icons.hourglass_top
                            : isActivelyListening ? Icons.mic
                            : Icons.mic_none,
                        size: 36, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Color(0xFFCCC9F5)),
                  decoration: const InputDecoration(
                      hintText: 'Type a command...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      setState(() => _convState = _ConvState.idle);
                      _processCommand(v.trim());
                      _textController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_textController.text.trim().isNotEmpty) {
                    setState(() => _convState = _ConvState.idle);
                    _processCommand(_textController.text.trim());
                    _textController.clear();
                  }
                },
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Visual list card shown when user asks for notes/reminders ─────────────────
class _ListCard extends StatelessWidget {
  final String header;
  final List<Map<String, String>> items;
  final IconData icon;
  final ColorScheme colorScheme;
  const _ListCard({required this.header, required this.items,
      required this.icon, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, backgroundColor: colorScheme.primary,
              child: const Text('N', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold, color: Colors.white))),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E3A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(children: [
                      Icon(icon, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(header, style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const Divider(height: 1, color: Color(0xFF2A2A4A)),
                  // Items
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary.withValues(alpha: 0.15),
                            ),
                            child: Center(child: Text('${idx + 1}',
                                style: TextStyle(color: colorScheme.primary,
                                    fontSize: 11, fontWeight: FontWeight.w600))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] ?? '', style: const TextStyle(
                                  color: Color(0xFFCCC9F5), fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                              if ((item['subtitle'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(item['subtitle'] ?? '', style: TextStyle(
                                    color: Colors.grey[500], fontSize: 11)),
                              ],
                            ],
                          )),
                        ]),
                      ),
                      if (idx < items.length - 1)
                        const Divider(height: 1, indent: 48, color: Color(0xFF2A2A4A)),
                    ]);
                  }),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text conversation bubble ──────────────────────────────────────────────────
class _ConversationBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final ColorScheme colorScheme;
  const _ConversationBubble(
      {required this.text, required this.isUser, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(radius: 14, backgroundColor: colorScheme.primary,
                child: const Text('N', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary.withValues(alpha: 0.25)
                    : const Color(0xFF1E1E3A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                    color: isUser
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    width: 1),
              ),
              child: Text(text, style: const TextStyle(
                  color: Color(0xFFCCC9F5), fontSize: 14, height: 1.5)),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}