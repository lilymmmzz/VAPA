import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart' as vapa;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _particleController;
  List<_Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(duration: const Duration(seconds: 10), vsync: this)..repeat();
    final random = Random();
    for (int i = 0; i < 30; i++) {
      particles.add(_Particle(x: random.nextDouble(), y: random.nextDouble(), size: random.nextDouble() * 3 + 1, speed: random.nextDouble() * 0.002 + 0.001, opacity: random.nextDouble() * 0.5 + 0.1));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<vapa.AuthProvider>(context, listen: false);
    final success = await authProvider.register(_emailController.text.trim(), _passwordController.text.trim());
    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.errorMessage ?? 'Registration failed'), backgroundColor: Colors.red));
      return;
    }

    if (success && mounted) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await user?.sendEmailVerification();
        // Sign out completely through AuthProvider so isAuthenticated becomes false
        await authProvider.logout();
      } catch (e) {
        debugPrint('Verification email error: $e');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => VerificationPendingScreen(email: _emailController.text.trim())),
        );
      }
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
          Positioned(
            top: 44, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1A2E), border: Border.all(color: const Color(0xFF2A2A45))),
                child: const Icon(Icons.arrow_back, color: Color(0xFF7F77DD), size: 18),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF26215C), border: Border.all(color: const Color(0xFF534AB7), width: 2)),
                          child: const Icon(Icons.person_add_outlined, color: Color(0xFF7F77DD), size: 36),
                        ),
                        const SizedBox(height: 12),
                        const Text('Get Started', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFAFA9EC), letterSpacing: 2)),
                        const SizedBox(height: 4),
                        const Text('Create your VAPA account', style: TextStyle(fontSize: 11, color: Color(0xFF534AB7), letterSpacing: 1)),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: const Color(0xFF1A1A2E).withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A2A45), width: 0.5)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Create Account', style: TextStyle(color: Color(0xFFE8E6FF), fontSize: 20, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              const Text('A verification email will be sent', style: TextStyle(color: Color(0xFF555566), fontSize: 12)),
                              const SizedBox(height: 20),
                              _buildField(_emailController, 'Email', Icons.email_outlined, false),
                              const SizedBox(height: 12),
                              _buildField(_passwordController, 'Password', Icons.lock_outlined, true, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                              const SizedBox(height: 12),
                              _buildField(_confirmPasswordController, 'Confirm Password', Icons.lock_outlined, true, obscure: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity, height: 46,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF534AB7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: _isLoading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Already have an account? Sign In', style: TextStyle(color: Color(0xFF7F77DD), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool isPassword, {bool obscure = false, VoidCallback? onToggle}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      style: const TextStyle(color: Color(0xFFCCC9F5), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF534AB7), size: 18),
        suffixIcon: isPassword ? IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF534AB7), size: 18), onPressed: onToggle) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF534AB7))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF534AB7))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7F77DD), width: 1.5)),
      ),
    );
  }
}

// ── Verification Pending Screen ───────────────────────────────────────────────
class VerificationPendingScreen extends StatefulWidget {
  final String email;
  const VerificationPendingScreen({super.key, required this.email});
  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> with TickerProviderStateMixin {
  late AnimationController _particleController;
  List<_Particle> particles = [];
  bool _isResending = false;

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
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _openEmailApp() async {
    // Try Gmail first, then fallback to mailto
    final gmailUri = Uri.parse('googlegmail://');
    final mailtoUri = Uri.parse('mailto:');
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri);
    } else if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please open your email app manually'), backgroundColor: Color(0xFF534AB7)),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email resent!'), backgroundColor: Color(0xFF1D9E75)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resend. Please try again.'), backgroundColor: Colors.red));
    }
    setState(() => _isResending = false);
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1D3A2A), border: Border.all(color: const Color(0xFF1D9E75), width: 2)),
                      child: const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF5DCAA5), size: 44),
                    ),
                    const SizedBox(height: 24),
                    const Text('Check Your Email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFAFA9EC))),
                    const SizedBox(height: 12),
                    Text('We sent a verification link to', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7777AA), fontSize: 14, height: 1.6)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _openEmailApp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26215C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF534AB7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined, color: Color(0xFF7F77DD), size: 16),
                            const SizedBox(width: 8),
                            Text(widget.email, style: const TextStyle(color: Color(0xFF7F77DD), fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openEmailApp,
                      child: const Text('Tap to open your email app →', style: TextStyle(color: Color(0xFF534AB7), fontSize: 12)),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A2E).withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2A45))),
                      child: Column(
                        children: [
                          _Step(number: '1', text: 'Open your email inbox'),
                          const SizedBox(height: 12),
                          _Step(number: '2', text: 'Click the verification link'),
                          const SizedBox(height: 12),
                          _Step(number: '3', text: 'Come back and sign in'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity, height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF534AB7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Go to Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isResending ? null : _resendEmail,
                      child: Text(_isResending ? 'Sending...' : 'Resend verification email', style: const TextStyle(color: Color(0xFF7F77DD), fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF26215C), border: Border.all(color: const Color(0xFF534AB7))),
          child: Center(child: Text(number, style: const TextStyle(color: Color(0xFF7F77DD), fontSize: 13, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Color(0xFFCCC9F5), fontSize: 14)),
      ],
    );
  }
}

// ── Particle system ───────────────────────────────────────────────────────────
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