import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/reminders_provider.dart';
import '../providers/mood_provider.dart';
import 'notes/notes_screen.dart';
import 'reminders/reminders_screen.dart';
import 'mood/mood_screen.dart';
import 'voice/voice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _novaController;
  late Animation<double> _novaAnimation;

  dynamic _voskService;
  bool _voskActive = false;
  bool _novaSheetOpen = false;

  final List<Widget> _screens = [
    const NotesScreen(),
    const RemindersScreen(),
    const MoodScreen(),
    const _ProfileScreen(),
  ];

  final List<String> _wakeWords = [
    'hey nova', 'nova', 'hey vapa', 'vapa', 'hey vapor', 'vapor',
  ];

  @override
  void initState() {
    super.initState();
    _novaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _novaAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(_novaController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.uid;
      if (userId != null) {
        Provider.of<NotesProvider>(context, listen: false).loadNotes(userId);
        Provider.of<RemindersProvider>(context, listen: false).loadReminders(userId);
        Provider.of<MoodProvider>(context, listen: false).loadMoods(userId);
      }
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _openNova();
      });
      if (!kIsWeb) _initVosk();
    });
  }

  Future<void> _initVosk() async {
    if (kIsWeb) return;
    try {
      debugPrint('=== VOSK HOME: Handled by WakeWordService ===');
    } catch (e) {
      debugPrint('=== VOSK HOME FAILED: $e ===');
    }
  }

  Future<void> _pauseVosk() async {
    if (kIsWeb) return;
    if (_voskService != null && _voskActive) {
      try {
        await _voskService!.stop();
        if (mounted) setState(() => _voskActive = false);
      } catch (_) {}
    }
  }

  Future<void> _resumeVosk() async {
    if (kIsWeb) return;
    if (_voskService != null && !_voskActive) {
      try {
        await _voskService!.start();
        if (mounted) setState(() => _voskActive = true);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _novaController.dispose();
    if (!kIsWeb) _voskService?.stop();
    super.dispose();
  }

  void _openNova() {
    if (_novaSheetOpen) return;
    _pauseVosk();
    setState(() => _novaSheetOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NovaSheet(),
    ).then((_) {
      setState(() => _novaSheetOpen = false);
      _resumeVosk();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use side navigation on wide screens (web/tablet)
    final isWide = MediaQuery.of(context).size.width > 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(
              currentIndex: _currentIndex,
              voskActive: _voskActive,
              novaAnimation: _novaAnimation,
              onTap: (i) => setState(() => _currentIndex = i),
              onNovaTap: _openNova,
            ),
            const VerticalDivider(width: 1, thickness: 0.5, color: VapaColors.border),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: VapaColors.navBg,
        border: Border(top: BorderSide(color: VapaColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.sticky_note_2_outlined, activeIcon: Icons.sticky_note_2, label: 'Notes', selected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
              _NavItem(icon: Icons.alarm_outlined, activeIcon: Icons.alarm, label: 'Reminders', selected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
              Expanded(
                child: GestureDetector(
                  onTap: _openNova,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _voskActive ? _novaAnimation : const AlwaysStoppedAnimation(1.0),
                        child: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _voskActive ? VapaColors.teal : VapaColors.purple,
                            border: Border.all(color: VapaColors.tealLight.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: const Icon(Icons.mic, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _voskActive ? 'Listening' : 'Nova',
                        style: const TextStyle(fontSize: 10, color: VapaColors.tealLight, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(icon: Icons.mood_outlined, activeIcon: Icons.mood, label: 'Mood', selected: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', selected: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Side navigation for wide screens (web/tablet) ─────────────────────────────
class _SideNav extends StatelessWidget {
  final int currentIndex;
  final bool voskActive;
  final Animation<double> novaAnimation;
  final void Function(int) onTap;
  final VoidCallback onNovaTap;

  const _SideNav({
    required this.currentIndex,
    required this.voskActive,
    required this.novaAnimation,
    required this.onTap,
    required this.onNovaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: VapaColors.navBg,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VapaColors.purple,
                    border: Border.all(color: VapaColors.tealLight.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('VAPA', style: TextStyle(color: VapaColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: VapaColors.border),
          const SizedBox(height: 12),
          _SideNavItem(icon: Icons.sticky_note_2_outlined, activeIcon: Icons.sticky_note_2, label: 'Notes', selected: currentIndex == 0, onTap: () => onTap(0)),
          _SideNavItem(icon: Icons.alarm_outlined, activeIcon: Icons.alarm, label: 'Reminders', selected: currentIndex == 1, onTap: () => onTap(1)),
          _SideNavItem(icon: Icons.mood_outlined, activeIcon: Icons.mood, label: 'Mood', selected: currentIndex == 2, onTap: () => onTap(2)),
          _SideNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', selected: currentIndex == 3, onTap: () => onTap(3)),
          const Spacer(),
          const Divider(height: 1, color: VapaColors.border),
          const SizedBox(height: 12),
          // Nova button at bottom of sidebar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: onNovaTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: VapaColors.purpleDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VapaColors.purple.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: voskActive ? novaAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: voskActive ? VapaColors.teal : VapaColors.purple,
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      voskActive ? 'Listening...' : 'Ask Nova',
                      style: const TextStyle(color: VapaColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? VapaColors.tealDim : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(selected ? activeIcon : icon, color: selected ? VapaColors.tealLight : VapaColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(color: selected ? VapaColors.tealLight : VapaColors.textMuted, fontSize: 14, fontWeight: selected ? FontWeight.w500 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav item ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: selected ? VapaColors.tealLight : VapaColors.textMuted, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: selected ? VapaColors.tealLight : VapaColors.textMuted, fontWeight: selected ? FontWeight.w500 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ── Nova bottom sheet ─────────────────────────────────────────────────────────
class _NovaSheet extends StatefulWidget {
  const _NovaSheet();
  @override
  State<_NovaSheet> createState() => _NovaSheetState();
}

class _NovaSheetState extends State<_NovaSheet> {
  String _greeting = 'Nova';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = auth.user?.email ?? '';
    if (email.isNotEmpty) {
      final raw = email.split('@')[0].split('.')[0];
      final name = raw[0].toUpperCase() + raw.substring(1);
      _greeting = 'Hi, $name!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: VapaColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: VapaColors.border, width: 0.5)),
          ),
          child: Column(
            children: [
              Center(child: Container(margin: const EdgeInsets.only(top: 10, bottom: 6), width: 36, height: 4, decoration: BoxDecoration(color: VapaColors.border, borderRadius: BorderRadius.circular(2)))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: VapaColors.purple, border: Border.all(color: VapaColors.tealLight.withValues(alpha: 0.4), width: 1.5)),
                      child: const Icon(Icons.mic, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: const TextStyle(color: VapaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const Text('Nova — Voice Assistant', style: TextStyle(color: VapaColors.tealLight, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, color: VapaColors.textMuted, size: 20), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Expanded(child: VoiceScreen()),
            ],
          ),
        );
      },
    );
  }
}

// ── Profile screen ────────────────────────────────────────────────────────────
class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.user?.email ?? 'Unknown';
    final initials = email.isNotEmpty ? email.substring(0, 2).toUpperCase() : 'VA';

    return Scaffold(
      backgroundColor: VapaColors.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: VapaColors.bg,
        toolbarHeight: 48,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Avatar — compact
          Center(
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VapaColors.purpleDim,
                    border: Border.all(color: VapaColors.purple, width: 2),
                  ),
                  child: Center(child: Text(initials, style: const TextStyle(color: VapaColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600))),
                ),
                const SizedBox(height: 8),
                Text(email, style: const TextStyle(color: VapaColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StatsRow(),
          const SizedBox(height: 16),
          const _SectionLabel('Settings'),
          _SettingsTile(icon: Icons.auto_awesome, label: 'AI Model', value: 'NVIDIA — Llama 3', onTap: () {}),
          _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', value: 'Enabled', onTap: () {}),
          const SizedBox(height: 12),
          const _SectionLabel('About'),
          _SettingsTile(icon: Icons.info_outline, label: 'VAPA Version', value: '1.0.0', onTap: () {}),
          _SettingsTile(icon: Icons.school_outlined, label: 'University of Bolton', value: 'SWE6010', onTap: () {}),
          const SizedBox(height: 16),
          // Sign out button — always visible
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: VapaColors.surface,
                    title: const Text('Sign out', style: TextStyle(color: VapaColors.textPrimary)),
                    content: const Text('Are you sure you want to sign out?', style: TextStyle(color: VapaColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: VapaColors.tealLight))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: const Text('Sign out', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notes = Provider.of<NotesProvider>(context);
    final reminders = Provider.of<RemindersProvider>(context);
    final moods = Provider.of<MoodProvider>(context);
    return Row(children: [
      _StatCard(label: 'Notes', value: '${notes.notes.length}'),
      const SizedBox(width: 10),
      _StatCard(label: 'Reminders', value: '${reminders.reminders.length}'),
      const SizedBox(width: 10),
      _StatCard(label: 'Moods', value: '${moods.moods.length}'),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: VapaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VapaColors.border, width: 0.5),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(color: VapaColors.tealLight, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: VapaColors.textMuted, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(), style: const TextStyle(color: VapaColors.tealLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.08)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: VapaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VapaColors.border, width: 0.5),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Icon(icon, color: VapaColors.textSecondary, size: 18),
        title: Text(label, style: const TextStyle(color: VapaColors.textPrimary, fontSize: 13)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: const TextStyle(color: VapaColors.textMuted, fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: VapaColors.textMuted, size: 16),
        ]),
      ),
    );
  }
}