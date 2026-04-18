import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart' as vapa;
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _selectedGoal = 'both';

  late AnimationController _particleController;
  List<_Particle> particles = [];

  final List<Map<String, dynamic>> _goals = [
    {'id': 'productivity', 'label': 'Productivity', 'emoji': '🚀', 'desc': 'Notes, reminders and tasks'},
    {'id': 'wellbeing', 'label': 'Wellbeing', 'emoji': '🧘', 'desc': 'Mood tracking and AI support'},
    {'id': 'both', 'label': 'Both', 'emoji': '⭐', 'desc': 'Full VAPA experience'},
  ];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(duration: const Duration(seconds: 10), vsync: this)..repeat();
    final random = Random();
    for (int i = 0; i < 20; i++) {
      particles.add(_Particle(x: random.nextDouble(), y: random.nextDouble(), size: random.nextDouble() * 2 + 1, speed: random.nextDouble() * 0.002 + 0.001, opacity: random.nextDouble() * 0.3 + 0.1));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your first name'), backgroundColor: Colors.red));
      return;
    }
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      _saveAndContinue();
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      final authProvider = Provider.of<vapa.AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final displayName = firstName.isNotEmpty ? firstName : 'User';

      // Use AuthProvider's updateDisplayName which sets hasCompletedSetup = true
      await authProvider.updateDisplayName(displayName);

      // Also save additional profile data to Firestore
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'firstName': firstName,
          'lastName': lastName,
          'displayName': displayName,
          'goal': _selectedGoal,
          'onboardingComplete': true,
          'hasCompletedSetup': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Onboarding save error: $e');
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen(openNovaOnLoad: true)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) => CustomPaint(painter: _ParticlePainter(particles: particles, progress: _particleController.value), size: Size.infinite),
          ),
          SafeArea(
            child: Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _currentPage ? const Color(0xFF534AB7) : const Color(0xFF2A2A45),
                        ),
                      ),
                    )),
                  ),
                ),
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildPage1(), _buildPage2(), _buildPage3()],
                  ),
                ),
                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          // Padding matches the card padding (20px) inside the 420 box
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              width: double.infinity, height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _nextPage,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF534AB7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                child: _isSaving
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(_currentPage < 2 ? 'Continue' : 'Get Started', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          if (_currentPage == 0) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _saveAndContinue,
                              child: const Text('Skip for now', style: TextStyle(color: Color(0xFF555566), fontSize: 13)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF26215C), border: Border.all(color: const Color(0xFF534AB7), width: 2)),
                child: const Icon(Icons.waving_hand, color: Color(0xFF7F77DD), size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Welcome to VAPA!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFAFA9EC))),
              const SizedBox(height: 8),
              const Text("I'm Nova, your personal assistant.\nWhat should I call you?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF7777AA), height: 1.5)),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E).withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A2A45), width: 0.5)),
                child: Column(
                  children: [
                    TextField(
                      controller: _firstNameController,
                      style: const TextStyle(color: Color(0xFFCCC9F5), fontSize: 14),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'First Name *', isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF534AB7), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF534AB7))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF534AB7))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7F77DD), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lastNameController,
                      style: const TextStyle(color: Color(0xFFCCC9F5), fontSize: 14),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Last Name (optional)', isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF534AB7), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF534AB7))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF534AB7))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7F77DD), width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('What is your main goal?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFAFA9EC))),
              const SizedBox(height: 8),
              const Text('This helps Nova personalise your experience', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF7777AA))),
              const SizedBox(height: 24),
              ..._goals.map((goal) {
                final isSelected = _selectedGoal == goal['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedGoal = goal['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF26215C) : const Color(0xFF1A1A2E).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF534AB7) : const Color(0xFF2A2A45), width: isSelected ? 1.5 : 0.5),
                    ),
                    child: Row(
                      children: [
                        Text(goal['emoji'], style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(goal['label'], style: TextStyle(color: isSelected ? const Color(0xFFE8E6FF) : const Color(0xFFAFA9EC), fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(goal['desc'], style: const TextStyle(color: Color(0xFF7777AA), fontSize: 12)),
                        ])),
                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF534AB7), size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage3() {
    final name = _firstNameController.text.trim().isEmpty ? 'there' : _firstNameController.text.trim();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1D3A2A), border: Border.all(color: const Color(0xFF1D9E75), width: 2)),
                child: const Icon(Icons.check, color: Color(0xFF5DCAA5), size: 44),
              ),
              const SizedBox(height: 20),
              Text("You're all set, $name! 🎉", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFAFA9EC))),
              const SizedBox(height: 8),
              const Text('Nova is ready to assist you.\nHere is what you can do:', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF7777AA), height: 1.5)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E).withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A2A45), width: 0.5)),
                child: Column(
                  children: [
                    _FeatureRow(emoji: '🎤', title: 'Say "Hey Nova"', desc: 'Activate voice commands anytime'),
                    const Divider(color: Color(0xFF2A2A45), height: 16),
                    _FeatureRow(emoji: '📝', title: 'Create Notes', desc: 'By voice or by typing'),
                    const Divider(color: Color(0xFF2A2A45), height: 16),
                    _FeatureRow(emoji: '⏰', title: 'Set Reminders', desc: 'Never miss anything important'),
                    const Divider(color: Color(0xFF2A2A45), height: 16),
                    _FeatureRow(emoji: '😊', title: 'Track Your Mood', desc: 'Daily check-ins with AI support'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _FeatureRow({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFFE8E6FF), fontSize: 13, fontWeight: FontWeight.w600)),
          Text(desc, style: const TextStyle(color: Color(0xFF7777AA), fontSize: 11)),
        ])),
      ],
    );
  }
}

class _Particle {
  double x, y, size, speed, opacity;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = const Color(0xFF7F77DD).withOpacity(p.opacity)..style = PaintingStyle.fill;
      double currentY = (p.y + progress * p.speed * 10) % 1.0;
      canvas.drawCircle(Offset(p.x * size.width, currentY * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}