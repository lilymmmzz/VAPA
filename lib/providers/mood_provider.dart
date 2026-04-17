import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/mood.dart';
import '../services/mood_service.dart';

class MoodProvider extends ChangeNotifier {
  final MoodService _moodService = MoodService();
  List<Mood> _moods = [];
  bool _isLoading = false;
  bool _hasLoggedToday = false;

  List<Mood> get moods => _moods;
  bool get isLoading => _isLoading;
  bool get hasLoggedToday => _hasLoggedToday;

  // Get mood emoji
  static String getMoodEmoji(int score) {
    switch (score) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '😊';
      case 5: return '😄';
      default: return '😐';
    }
  }

  // Get mood label
  static String getMoodLabel(int score) {
    switch (score) {
      case 1: return 'Terrible';
      case 2: return 'Bad';
      case 3: return 'Okay';
      case 4: return 'Good';
      case 5: return 'Amazing';
      default: return 'Okay';
    }
  }

  // Get mood color
  static Color getMoodColor(int score) {
    switch (score) {
      case 1: return const Color(0xFFE24B4A);
      case 2: return const Color(0xFFEF9F27);
      case 3: return const Color(0xFF7F77DD);
      case 4: return const Color(0xFF1D9E75);
      case 5: return const Color(0xFF5DCAA5);
      default: return const Color(0xFF7F77DD);
    }
  }

  // Load moods
  void loadMoods(String userId) {
    _isLoading = true;
    notifyListeners();

    _moodService.getMoods(userId).listen((moods) {
      _moods = moods;
      _isLoading = false;
      notifyListeners();
    });

    _checkTodayMood(userId);
  }

  // Check today's mood
  Future<void> _checkTodayMood(String userId) async {
    _hasLoggedToday = await _moodService.hasMoodToday(userId);
    notifyListeners();
  }

  // Save mood
  Future<void> saveMood(
      String userId, int score, String note) async {
    final mood = Mood(
      id: const Uuid().v4(),
      userId: userId,
      moodScore: score,
      moodLabel: getMoodLabel(score),
      note: note,
      createdAt: DateTime.now(),
    );
    await _moodService.saveMood(mood);
    _hasLoggedToday = true;
    notifyListeners();
  }

  // Delete mood
  Future<void> deleteMood(String userId, String moodId) async {
    await _moodService.deleteMood(userId, moodId);
  }
// Log mood from voice — converts text sentiment to score
Future<void> logMoodFromVoice(String userId, String moodWord, String note) async {
  final score = _moodWordToScore(moodWord.toLowerCase().trim());
  await saveMood(userId, score, note);
}

int _moodWordToScore(String word) {
  const map = {
    'amazing': 5, 'fantastic': 5, 'great': 5, 'excellent': 5, 'excited': 5,
    'happy': 4, 'good': 4, 'positive': 4, 'cheerful': 4, 'content': 4,
    'okay': 3, 'neutral': 3, 'fine': 3, 'alright': 3, 'calm': 3,
    'sad': 2, 'tired': 2, 'anxious': 2, 'stressed': 2, 'bad': 2,
    'terrible': 1, 'awful': 1, 'angry': 1, 'depressed': 1, 'horrible': 1,
  };
  return map[word] ?? 3; // default to neutral
}
  // Clear moods on logout
  void clearMoods() {
    _moods = [];
    _hasLoggedToday = false;
    notifyListeners();
  }

  // Get average mood this week
  double getWeeklyAverage() {
    if (_moods.isEmpty) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekMoods =
        _moods.where((m) => m.createdAt.isAfter(weekAgo)).toList();
    if (weekMoods.isEmpty) return 0;
    final total =
        weekMoods.fold(0, (sum, m) => sum + m.moodScore);
    return total / weekMoods.length;
  }
}