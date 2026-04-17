import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    final random = Random();
    for (int i = 0; i < 30; i++) {
      particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.002 + 0.001,
        opacity: random.nextDouble() * 0.5 + 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Color(0xFFCCC9F5)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email and we will send you a reset link.',
              style: TextStyle(color: Color(0xFF7777AA), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Color(0xFFCCC9F5)),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Color(0xFF7777AA)),
                prefixIcon: const Icon(Icons.email_outlined,
                    color: Color(0xFF534AB7)),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF534AB7)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF7F77DD))),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider
                  .resetPassword(emailController.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password reset email sent! Check your inbox.'
                          : authProvider.errorMessage ?? 'Error sending email',
                    ),
                    backgroundColor:
                        success ? const Color(0xFF534AB7) : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send Reset Link',
                style: TextStyle(color: Color(0xFFAFA9EC))),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _pulseAnimation.value * 1.3,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF534AB7)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _pulseAnimation.value * 1.15,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF534AB7)
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF26215C),
                                border: Border.all(
                                  color: const Color(0xFF534AB7),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: CustomPaint(
                                  painter: AvatarPainter(),
                                  size: const Size(90, 90),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'VAPA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAFA9EC),
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Voice Activated Personal Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF534AB7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFFCCC9F5)),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Color(0xFF534AB7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF534AB7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Color(0xFFCCC9F5)),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined,
                          color: Color(0xFF534AB7)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF534AB7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF534AB7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                            color: Color(0xFF7F77DD), fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF534AB7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Sign In',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Color(0xFF7F77DD)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  double x, y, size, speed, opacity;
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = const Color(0xFF7F77DD).withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      double currentY = (p.y + progress * p.speed * 10) % 1.0;
      canvas.drawCircle(
        Offset(p.x * size.width, currentY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      size.width / 2,
      Paint()..color = const Color(0xFF26215C),
    );

    canvas.drawCircle(
      Offset(center.dx, center.dy - 5),
      22,
      Paint()..color = const Color(0xFF7F77DD),
    );

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy + 28), width: 36, height: 22),
      Paint()..color = const Color(0xFF534AB7),
    );

    final eyePaint = Paint()..color = const Color(0xFFCCC9F5);
    canvas.drawCircle(Offset(center.dx - 7, center.dy - 7), 4, eyePaint);
    canvas.drawCircle(Offset(center.dx + 7, center.dy - 7), 4, eyePaint);

    final pupilPaint = Paint()..color = const Color(0xFF26215C);
    canvas.drawCircle(Offset(center.dx - 7, center.dy - 7), 2, pupilPaint);
    canvas.drawCircle(Offset(center.dx + 7, center.dy - 7), 2, pupilPaint);

    final smilePaint = Paint()
      ..color = const Color(0xFFCCC9F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy - 3), width: 16, height: 10),
      0,
      3.14,
      false,
      smilePaint,
    );

    final antennaPaint = Paint()
      ..color = const Color(0xFFAFA9EC)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - 27),
      Offset(center.dx, center.dy - 35),
      antennaPaint,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - 36),
      3,
      Paint()..color = const Color(0xFFAFA9EC),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}