import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/mood_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
        titleTextStyle: TextStyle(
          color: VapaColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VapaColors.navBg,
        indicatorColor: VapaColors.tealDim,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: VapaColors.tealLight, fontSize: 11, fontWeight: FontWeight.w500);
          }
          return const TextStyle(color: VapaColors.textMuted, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: VapaColors.tealLight, size: 22);
          }
          return const IconThemeData(color: VapaColors.textMuted, size: 22);
        }),
      ),
      cardTheme: const CardThemeData(
        color: VapaColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: VapaColors.border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VapaColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: VapaColors.borderAlt),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: VapaColors.borderAlt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: VapaColors.tealLight, width: 1.5),
        ),
        labelStyle: const TextStyle(color: VapaColors.textMuted),
        hintStyle: const TextStyle(color: VapaColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VapaColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: VapaColors.tealLight),
      ),
      dividerTheme: const DividerThemeData(
        color: VapaColors.border,
        thickness: 0.5,
        space: 0,
      ),
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
        backgroundColor: VapaColors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }
}

// ── Auth wrapper — StatefulWidget so it doesn't rebuild LoginScreen ───────────
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
