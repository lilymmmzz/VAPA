import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../services/gemini_provider.dart';
import '../../services/ai_provider.dart';

class MoodChatScreen extends StatefulWidget {
  final int initialMood;
  const MoodChatScreen({super.key, required this.initialMood});

  @override
  State<MoodChatScreen> createState() => _MoodChatScreenState();
}

class _MoodChatScreenState extends State<MoodChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final List<Map<String, String>> _messages = [];
  late final AIProvider _aiProvider;
  bool _isLoading = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _startConversation();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-Uk');
    await _flutterTts.setSpeechRate(0.95);
    await _flutterTts.setVolume(4.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVoice({'name': 'en-uk-x-iog-network', 'locale': 'en-Uk'});
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(text);
    setState(() => _isSpeaking = false);
  }

  Future<void> _startConversation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final moodLabel = MoodProvider.getMoodLabel(widget.initialMood);
    final moodEmoji = MoodProvider.getMoodEmoji(widget.initialMood);
    final userName = authProvider.user?.email?.split('@')[0] ?? 'friend';

    _aiProvider = GeminiProvider(
      systemPrompt:
          'You are VAPA, a warm, empathetic AI mood companion. '
          'The user $userName is feeling $moodLabel $moodEmoji. '
          'Listen actively, ask thoughtful questions, provide emotional support. '
          'Keep responses to 2-3 sentences, warm and conversational like a caring friend.',
    );

    final openingMessage =
        'Hi! I can see you\'re feeling $moodLabel today. '
        'I\'m VAPA, your personal mood companion. '
        'Would you like to talk about how you\'re feeling?';

    setState(() => _messages.add({'role': 'assistant', 'content': openingMessage}));
    await _speak(openingMessage);
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final aiResponse = await _aiProvider.sendMessage(userMessage);
      setState(() {
        _messages.add({'role': 'assistant', 'content': aiResponse});
        _isLoading = false;
      });
      _scrollToBottom();
      await _speak(aiResponse);
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Sorry, I had trouble responding. Please try again.'});
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        foregroundColor: const Color(0xFFAFA9EC),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF26215C),
                border: Border.all(color: const Color(0xFF534AB7)),
              ),
              child: Center(child: Text(MoodProvider.getMoodEmoji(widget.initialMood), style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VAPA Mood Chat', style: TextStyle(color: Color(0xFFAFA9EC), fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _isSpeaking ? 'Speaking...' : 'Online',
                  style: TextStyle(color: _isSpeaking ? const Color(0xFF7F77DD) : const Color(0xFF1D9E75), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_off, color: const Color(0xFF7F77DD)),
            onPressed: () { if (_isSpeaking) { _flutterTts.stop(); setState(() => _isSpeaking = false); } },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) return _buildTypingIndicator();
                final message = _messages[index];
                return _buildMessage(message['content']!, message['role'] == 'user');
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF12122A),
              border: Border(top: BorderSide(color: Color(0xFF3C3489), width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Color(0xFFCCC9F5)),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Talk to VAPA...',
                      hintStyle: const TextStyle(color: Color(0xFF7777AA)),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF534AB7))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF534AB7))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF534AB7)),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF26215C), border: Border.all(color: const Color(0xFF534AB7))),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF534AB7) : const Color(0xFF12122A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: const Color(0xFF3C3489)),
              ),
              child: Text(content, style: TextStyle(color: isUser ? Colors.white : const Color(0xFFCCC9F5), fontSize: 14)),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF26215C), border: Border.all(color: const Color(0xFF534AB7))),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF12122A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF3C3489))),
            child: Row(
              children: [_buildDot(0), const SizedBox(width: 4), _buildDot(1), const SizedBox(width: 4), _buildDot(2)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7F77DD).withValues(alpha: 0.3 + (value * 0.7)),
          ),
        );
      },
    );
  }
}