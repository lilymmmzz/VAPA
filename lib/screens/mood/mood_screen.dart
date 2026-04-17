import 'mood_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  int _selectedMood = 3;
  final _noteController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

Future<void> _initTts() async {
  await _flutterTts.setLanguage('en-Uk');
  await _flutterTts.setSpeechRate(0.85);
  await _flutterTts.setVolume(1.0);
  await _flutterTts.setPitch(1.0);

  await _flutterTts.setVoice({
    'name': 'en-uk-x-iog-network',
    'locale': 'en-US',
  });
}

  @override
  void dispose() {
    _noteController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

Future<void> _saveMood() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final moodProvider = Provider.of<MoodProvider>(context, listen: false);
  final userId = authProvider.user?.uid ?? '';

  await moodProvider.saveMood(
      userId, _selectedMood, _noteController.text.trim());

  if (mounted) {
    _noteController.clear();
    // Navigate to AI chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodChatScreen(initialMood: _selectedMood),
      ),
    );
  }
}
@override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    final weeklyAverage = moodProvider.getWeeklyAverage();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly average card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF12122A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3C3489)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF26215C),
                      border: Border.all(color: const Color(0xFF534AB7)),
                    ),
                    child: Center(
                      child: Text(
                        weeklyAverage > 0
                            ? MoodProvider.getMoodEmoji(
                                weeklyAverage.round())
                            : '📊',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Mood Average',
                        style: TextStyle(
                          color: Color(0xFF7777AA),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weeklyAverage > 0
                            ? MoodProvider.getMoodLabel(
                                weeklyAverage.round())
                            : 'No data yet',
                        style: const TextStyle(
                          color: Color(0xFFCCC9F5),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's mood section
            if (!moodProvider.hasLoggedToday) ...[
              const Text(
                'How are you feeling today?',
                style: TextStyle(
                  color: Color(0xFFAFA9EC),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Mood selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  final score = index + 1;
                  final isSelected = _selectedMood == score;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = score),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 64 : 52,
                      height: isSelected ? 64 : 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? MoodProvider.getMoodColor(score)
                                .withValues(alpha: (0.3 * 255).roundToDouble())
                            : const Color(0xFF12122A),
                        border: Border.all(
                          color: isSelected
                              ? MoodProvider.getMoodColor(score)
                              : const Color(0xFF3C3489),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          MoodProvider.getMoodEmoji(score),
                          style: TextStyle(
                              fontSize: isSelected ? 28 : 22),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  MoodProvider.getMoodLabel(_selectedMood),
                  style: TextStyle(
                    color: MoodProvider.getMoodColor(_selectedMood),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Note field
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Color(0xFFCCC9F5)),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note about your day (optional)...',
                  hintStyle: const TextStyle(color: Color(0xFF7777AA)),
                  filled: true,
                  fillColor: const Color(0xFF12122A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF534AB7)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF534AB7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Log My Mood',
                      style:
                          TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF12122A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1D9E75)),
                ),
                child: const Row(
                  children: [
                    Text('✅', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood logged today!',
                          style: TextStyle(
                            color: Color(0xFF5DCAA5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Come back tomorrow',
                          style: TextStyle(
                            color: Color(0xFF7777AA),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Mood history
            const Text(
              'Mood History',
              style: TextStyle(
                color: Color(0xFFAFA9EC),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            moodProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7F77DD)))
                : moodProvider.moods.isEmpty
                    ? const Center(
                        child: Text(
                          'No mood history yet',
                          style: TextStyle(color: Color(0xFF534AB7)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: moodProvider.moods.length,
                        itemBuilder: (context, index) {
                          final mood = moodProvider.moods[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12122A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: MoodProvider.getMoodColor(
                                        mood.moodScore)
                                    .withValues(alpha: (0.3 * 255).roundToDouble()),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  MoodProvider.getMoodEmoji(
                                      mood.moodScore),
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mood.moodLabel,
                                        style: TextStyle(
                                          color: MoodProvider
                                              .getMoodColor(
                                                  mood.moodScore),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (mood.note.isNotEmpty)
                                        Text(
                                          mood.note,
                                          style: const TextStyle(
                                            color: Color(0xFF7777AA),
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        '${mood.createdAt.day}/${mood.createdAt.month}/${mood.createdAt.year}',
                                        style: const TextStyle(
                                          color: Color(0xFF534AB7),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18),
                                  onPressed: () =>
                                      moodProvider.deleteMood(
                                          userId, mood.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}

