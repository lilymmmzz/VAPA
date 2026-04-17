import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';
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
  bool _isLoading = false; // local loading state — not from provider
  String? _emailError;
  String? _passwordError;
  String? _generalError;

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

  void _handleAuthError(String? error) {
    if (error == null) {
      setState(() => _generalError =
      'Sign in failed. Please check your details and try again.');
      return;
    }

    final e = error.toLowerCase();
    print('=== AUTH ERROR RAW: $error ===');

    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;

      if (e.contains('wrong-password') ||
          e.contains('invalid-credential') ||
          e.contains('user-not-found') ||
          e.contains('invalid-login') ||
          e.contains('invalid-password')) {
        _passwordError = 'Incorrect email or password. Please try again.';
      } else if (e.contains('invalid-email')) {
        _emailError = 'Please enter a valid email address.';
      } else if (e.contains('too-many-requests')) {
        _generalError =
        'Too many failed attempts. Please wait a few minutes and try again.';
      } else if (e.contains('network') || e.contains('connection')) {
        _generalError =
        'No internet connection. Please check your network and try again.';
      } else if (e.contains('user-disabled')) {
        _emailError = 'This account has been disabled. Contact support.';
      } else {
        _generalError = 'Sign in failed. Please try again.';
      }
    });
  }

  Future<void> _login() async {
    // Clear errors
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate locally first
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters.');
      return;
    }

    // Use LOCAL loading state — not provider's isLoading
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Navigate directly — don't wait for AuthWrapper to rebuild
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } else {
      _handleAuthError(authProvider.errorMessage);
    }
  }

  void _showForgotPasswordDialog() {
    final emailController =
    TextEditingController(text: _emailController.text.trim());
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: VapaColors.surface,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reset password',
              style: TextStyle(
                  color: VapaColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email and we\'ll send you a reset link.',
                style:
                TextStyle(color: VapaColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: VapaColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: VapaColors.purple, size: 20),
                  errorText: dialogError,
                  filled: true,
                  fillColor: VapaColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: VapaColors.borderAlt),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: VapaColors.borderAlt),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: VapaColors.tealLight, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: VapaColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  setDialogState(
                          () => dialogError = 'Please enter your email.');
                  return;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(email)) {
                  setDialogState(() =>
                  dialogError = 'Please enter a valid email address.');
                  return;
                }
                final authProvider =
                Provider.of<AuthProvider>(ctx, listen: false);
                final success = await authProvider.resetPassword(email);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _showResetFeedback(success, authProvider.errorMessage);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VapaColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetFeedback(bool success, String? error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VapaColors.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: success ? VapaColors.tealLight : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              success ? 'Email sent!' : 'Failed to send',
              style: TextStyle(
                  color: success ? VapaColors.tealLight : Colors.red,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          success
              ? 'A password reset link has been sent to your email. Check your inbox and spam folder.'
              : error ?? 'Could not send reset email. Please try again.',
          style:
          const TextStyle(color: VapaColors.textSecondary, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: success ? VapaColors.teal : VapaColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use listen: false — we manage our own loading state locally
    // This prevents the screen from rebuilding when provider changes
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

                  // ── Animated avatar ────────────────────────────────────
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

                  // ── General error banner ───────────────────────────────
                  if (_generalError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                        Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Email field ────────────────────────────────────────
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFFCCC9F5)),
                    onChanged: (_) => setState(() => _emailError = null),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Color(0xFF534AB7)),
                      errorText: _emailError,
                      errorStyle:
                      const TextStyle(color: Colors.red, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _emailError != null
                              ? Colors.red
                              : const Color(0xFF534AB7),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _emailError != null
                              ? Colors.red
                              : const Color(0xFF534AB7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ─────────────────────────────────────
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Color(0xFFCCC9F5)),
                    onChanged: (_) => setState(() => _passwordError = null),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined,
                          color: Color(0xFF534AB7)),
                      errorText: _passwordError,
                      errorStyle:
                      const TextStyle(color: Colors.red, fontSize: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF534AB7),
                        ),
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordError != null
                              ? Colors.red
                              : const Color(0xFF534AB7),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordError != null
                              ? Colors.red
                              : const Color(0xFF534AB7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Forgot password ────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot password?',
                        style:
                        TextStyle(color: Color(0xFF7F77DD), fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Sign in button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF534AB7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Sign in',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Register link ──────────────────────────────────────
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
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

// ── Particle system ───────────────────────────────────────────────────────────
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
    canvas.drawCircle(center, size.width / 2,
        Paint()..color = const Color(0xFF26215C));
    canvas.drawCircle(Offset(center.dx, center.dy - 5), 22,
        Paint()..color = const Color(0xFF7F77DD));
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
      0, 3.14, false, smilePaint,
    );
    final antennaPaint = Paint()
      ..color = const Color(0xFFAFA9EC)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy - 27),
        Offset(center.dx, center.dy - 35), antennaPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - 36), 3,
        Paint()..color = const Color(0xFFAFA9EC));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
