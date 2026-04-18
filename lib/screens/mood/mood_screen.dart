import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import 'mood_chat_screen.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> with TickerProviderStateMixin {
  int _selectedMood = 3;
  final _noteController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initTts();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(_pulseController);
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-UK');
    await _flutterTts.setSpeechRate(0.85);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVoice({'name': 'en-uk-x-iog-network', 'locale': 'en-US'});
    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setCancelHandler(() => setState(() => _isSpeaking = false));
  }

  Future<void> _speakMoodLabel() async {
    if (_isSpeaking) { await _flutterTts.stop(); return; }
    await _flutterTts.speak('Your mood is ${MoodProvider.getMoodLabel(_selectedMood)}');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _pulseController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _saveMood() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';
    await moodProvider.saveMood(userId, _selectedMood, _noteController.text.trim());
    if (mounted) {
      _noteController.clear();
      Navigator.push(context, MaterialPageRoute(builder: (_) => MoodChatScreen(initialMood: _selectedMood)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    final weeklyAverage = moodProvider.getWeeklyAverage();

    return Scaffold(
      backgroundColor: VapaColors.bg,
      appBar: AppBar(
        title: const Text('Mood'),
        backgroundColor: VapaColors.bg,
        toolbarHeight: 48,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _speakMoodLabel,
              child: ScaleTransition(
                scale: _isSpeaking ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSpeaking ? VapaColors.teal : VapaColors.purple,
                    border: Border.all(color: VapaColors.tealLight.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_up_outlined, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Weekly average card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: VapaColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VapaColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: VapaColors.purpleDim, border: Border.all(color: VapaColors.purple)),
                        child: Center(child: Text(weeklyAverage > 0 ? MoodProvider.getMoodEmoji(weeklyAverage.round()) : '📊', style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Mood Average', style: TextStyle(color: VapaColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(weeklyAverage > 0 ? MoodProvider.getMoodLabel(weeklyAverage.round()) : 'No data yet', style: const TextStyle(color: VapaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      if (weeklyAverage > 0)
                        Text(weeklyAverage.toStringAsFixed(1), style: const TextStyle(color: VapaColors.tealLight, fontSize: 20, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Today's mood / already logged ────────────────────────
                if (!moodProvider.hasLoggedToday) ...[
                  const Text('How are you feeling today?', style: TextStyle(color: VapaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(color: VapaColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: VapaColors.border)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(5, (index) {
                            final score = index + 1;
                            final isSelected = _selectedMood == score;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMood = score),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 52 : 40,
                                height: isSelected ? 52 : 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? MoodProvider.getMoodColor(score).withValues(alpha: 0.3) : VapaColors.surfaceAlt,
                                  border: Border.all(color: isSelected ? MoodProvider.getMoodColor(score) : VapaColors.border, width: isSelected ? 2 : 1),
                                ),
                                child: Center(child: Text(MoodProvider.getMoodEmoji(score), style: TextStyle(fontSize: isSelected ? 22 : 17))),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(MoodProvider.getMoodLabel(_selectedMood), style: TextStyle(color: MoodProvider.getMoodColor(_selectedMood), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(color: VapaColors.textPrimary, fontSize: 13),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add a note about your day (optional)...',
                      hintStyle: const TextStyle(color: VapaColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: VapaColors.surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VapaColors.tealLight, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _saveMood,
                      icon: const Icon(Icons.mood, size: 17),
                      label: const Text('Log My Mood', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      style: ElevatedButton.styleFrom(backgroundColor: VapaColors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: VapaColors.tealDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: VapaColors.teal)),
                    child: const Row(
                      children: [
                        Text('✅', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mood logged today!', style: TextStyle(color: VapaColors.tealLight, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Come back tomorrow', style: TextStyle(color: VapaColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MoodChatScreen(initialMood: _selectedMood))),
                      icon: const Icon(Icons.mic, size: 17),
                      label: const Text('Chat with Nova', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      style: ElevatedButton.styleFrom(backgroundColor: VapaColors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // ── Mood history ─────────────────────────────────────────
                const Text('Mood History', style: TextStyle(color: VapaColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                moodProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: VapaColors.tealLight))
                    : moodProvider.moods.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: VapaColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: VapaColors.border)),
                            child: const Center(child: Text('No mood history yet', style: TextStyle(color: VapaColors.textMuted, fontSize: 12))),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: moodProvider.moods.length,
                            itemBuilder: (context, index) {
                              final mood = moodProvider.moods[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: VapaColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: MoodProvider.getMoodColor(mood.moodScore).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Text(MoodProvider.getMoodEmoji(mood.moodScore), style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(mood.moodLabel, style: TextStyle(color: MoodProvider.getMoodColor(mood.moodScore), fontWeight: FontWeight.w600, fontSize: 12)),
                                          if (mood.note.isNotEmpty) Text(mood.note, style: const TextStyle(color: VapaColors.textMuted, fontSize: 11)),
                                          Text('${mood.createdAt.day}/${mood.createdAt.month}/${mood.createdAt.year}', style: const TextStyle(color: VapaColors.textMuted, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                      onPressed: () => moodProvider.deleteMood(userId, mood.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}