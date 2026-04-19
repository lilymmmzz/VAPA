import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as vapa;
import 'providers/notes_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/mood_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/gemini_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const VapaApp());
}

// ── Colour tokens ─────────────────────────────────────────────────────────────
class VapaColors {
  static const bg         = Color(0xFF13131F);
  static const surface    = Color(0xFF1A1A2E);
  static const surfaceAlt = Color(0xFF1E1E30);
  static const navBg      = Color(0xFF0D0D18);
  static const border     = Color(0xFF2A2A45);
  static const borderAlt  = Color(0xFF2E2E50);
  static const purple     = Color(0xFF534AB7);
  static const purpleLight= Color(0xFF7F77DD);
  static const purpleDim  = Color(0xFF26215C);
  static const teal       = Color(0xFF1D9E75);
  static const tealLight  = Color(0xFF5DCAA5);
  static const tealDim    = Color(0xFF1D3A2A);
  static const textPrimary   = Color(0xFFE8E6FF);
  static const textSecondary = Color(0xFFAFA9EC);
  static const textMuted     = Color(0xFF555566);
}

// ── App entry ─────────────────────────────────────────────────────────────────
class VapaApp extends StatelessWidget {
  const VapaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => vapa.AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => RemindersProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: MaterialApp(
        title: 'VAPA',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AuthWrapper(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary:    VapaColors.purple,
        secondary:  VapaColors.teal,
        tertiary:   VapaColors.tealLight,
        surface:    VapaColors.surface,
        onPrimary:  Colors.white,
        onSecondary: Colors.white,
        onSurface:  VapaColors.textPrimary,
      ),
      scaffoldBackgroundColor: VapaColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: VapaColors.bg,
        foregroundColor: VapaColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: VapaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VapaColors.navBg,
        indicatorColor: VapaColors.tealDim,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const TextStyle(color: VapaColors.tealLight, fontSize: 11, fontWeight: FontWeight.w500);
          return const TextStyle(color: VapaColors.textMuted, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const IconThemeData(color: VapaColors.tealLight, size: 22);
          return const IconThemeData(color: VapaColors.textMuted, size: 22);
        }),
      ),
      cardTheme: const CardThemeData(
        color: VapaColors.surface, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)), side: BorderSide(color: VapaColors.border, width: 0.5)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: VapaColors.surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: VapaColors.borderAlt)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: VapaColors.borderAlt)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: VapaColors.tealLight, width: 1.5)),
        labelStyle: const TextStyle(color: VapaColors.textMuted),
        hintStyle: const TextStyle(color: VapaColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VapaColors.purple, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: VapaColors.tealLight)),
      dividerTheme: const DividerThemeData(color: VapaColors.border, thickness: 0.5, space: 0),
      iconTheme: const IconThemeData(color: VapaColors.textSecondary, size: 22),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(color: VapaColors.textPrimary,   fontSize: 28, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: VapaColors.textPrimary,   fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge:     TextStyle(color: VapaColors.textPrimary,   fontSize: 18, fontWeight: FontWeight.w500),
        titleMedium:    TextStyle(color: VapaColors.textPrimary,   fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall:     TextStyle(color: VapaColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge:      TextStyle(color: VapaColors.textPrimary,   fontSize: 16),
        bodyMedium:     TextStyle(color: VapaColors.textSecondary, fontSize: 14),
        bodySmall:      TextStyle(color: VapaColors.textMuted,     fontSize: 12),
        labelSmall:     TextStyle(color: VapaColors.textMuted,     fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: VapaColors.purple, foregroundColor: Colors.white, elevation: 0, shape: CircleBorder(),
      ),
    );
  }
}

// ── Auth wrapper ──────────────────────────────────────────────────────────────
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<vapa.AuthProvider>(context);

    // 1. Not logged in
    if (!auth.isAuthenticated) return const LoginScreen();

    // 2. Logged in but email not verified — sign out and show login with error
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && !firebaseUser.emailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await auth.logout();
      });
      return const LoginScreen(
        errorMessage: 'Please verify your email before signing in. Check your inbox for the verification link.',
      );
    }

    // 3. Verified but onboarding not done
    if (!auth.hasCompletedSetup) return const OnboardingScreen();

    // 4. All good
    return const HomeScreen();
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withOpacity(0.15), border: Border.all(color: Colors.orange, width: 2)),
                  child: const Icon(Icons.mark_email_unread_outlined, color: Colors.orange, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('Email Not Verified', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFAFA9EC))),
                const SizedBox(height: 12),
                const Text(
                  'Your email address has not been verified.\n\nPlease check your inbox and click the verification link before signing in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7777AA), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF534AB7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Go to Sign In', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
