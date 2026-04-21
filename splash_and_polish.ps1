# Splash screen + UI polish

function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $path" -ForegroundColor Cyan
}

# ══════════════════════════════════════════════════════════════════════════════
# Splash Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\splash\splash_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeIn)));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    final isLoggedIn = auth.valueOrNull != null;
    if (mounted) context.go(isLoggedIn ? '/home' : '/login');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Logo
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.music_note, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 28),
              const Text('Asempa Choir',
                  style: TextStyle(color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('NUPS-G UMaT',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 16)),
              const SizedBox(height: 60),
              SizedBox(width: 28, height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.6),
                  strokeWidth: 2.5,
                )),
            ]),
          ),
        ),
      ),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Update router to include splash screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\router\router.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/checkin/checkin_screen.dart';
import '../features/attendance/attendance_history_screen.dart';
import '../features/music/music_library_screen.dart';
import '../features/quiet_time/quiet_time_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/directory/directory_screen.dart';
import '../features/announcements/announcements_screen.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
          GoRoute(path: '/communication', builder: (_, __) => const _UnderConstruction()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
        ],
      ),
      GoRoute(path: '/checkin', builder: (_, __) => const CheckInScreen()),
      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceHistoryScreen()),
      GoRoute(path: '/music', builder: (_, __) => const MusicLibraryScreen()),
      GoRoute(path: '/quiet-time', builder: (_, __) => const QuietTimeScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/directory', builder: (_, __) => const DirectoryScreen()),
      GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsScreen()),
    ],
  );
});

class _UnderConstruction extends StatelessWidget {
  const _UnderConstruction();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communication')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.construction, size: 80, color: Colors.orange.shade400),
        const SizedBox(height: 24),
        Text('Under Construction', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text('Group chat, announcements and messaging\ncoming soon!',
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Stay tuned...', style: TextStyle(color: Colors.grey)),
      ])),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Polished Main Shell with better bottom nav
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\shared\widgets\main_shell.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/communication')) return 2;
    if (location.startsWith('/admin')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home,
                    label: 'Home', index: 0, current: currentIndex,
                    onTap: () => context.go('/home')),
                _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today,
                    label: 'Schedule', index: 1, current: currentIndex,
                    onTap: () => context.go('/schedule')),
                _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications,
                    label: 'Updates', index: 2, current: currentIndex,
                    onTap: () => context.go('/communication')),
                _NavItem(
                    icon: user?.isAdmin == true
                        ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                    activeIcon: user?.isAdmin == true
                        ? Icons.admin_panel_settings : Icons.person,
                    label: user?.isAdmin == true ? 'Admin' : 'Profile',
                    index: 3, current: currentIndex,
                    onTap: () => context.go('/admin')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon,
      required this.label, required this.index, required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textHint, size: 24),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppColors.primary : AppColors.textHint)),
        ]),
      ),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Polished Login Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\auth\login_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false, _obscurePass = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _animCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).login(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.contains('invalid-credential') || msg.contains('wrong-password')
          ? 'Invalid email or password.'
          : msg.contains('too-many-requests') ? 'Too many attempts. Try again later.'
          : 'Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.primary),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Logo
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: const Icon(Icons.music_note, size: 54, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('Asempa Choir',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('NUPS-G UMaT',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15)),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Sign in to continue', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl, obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account? ", style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text('Register',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ])),
                ),
              ]),
            )),
          ),
        ),
      ),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Polished Register Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\auth\register_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _voicePart = 'SOPRANO';
  bool _loading = false, _obscurePass = true;
  String? _error;

  static const _parts = ['SOPRANO','ALTO','TENOR','BASS','PIANO','DRUMS','GUITAR'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).register(
        name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(),
        password: _passCtrl.text, phone: _phoneCtrl.text.trim(),
        voicePart: _voicePart);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account created! Awaiting admin approval.')));
        context.go('/home');
      }
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.contains('email-already-in-use')
          ? 'This email is already registered.'
          : 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(children: [
            const Icon(Icons.music_note, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            const Text('Join Asempa Choir',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            Text('Create your account',
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(controller: _nameCtrl, textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined), hintText: '+233...'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _voicePart,
                  decoration: const InputDecoration(labelText: 'Voice / Instrument',
                      prefixIcon: Icon(Icons.music_note_outlined)),
                  items: _parts.map((p) => DropdownMenuItem(value: p,
                      child: Row(children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: voicePartColor(p), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(p),
                      ]))).toList(),
                  onChanged: (v) => setState(() => _voicePart = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(controller: _passCtrl, obscureText: _obscurePass,
                    decoration: InputDecoration(labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass))),
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ])),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 14),
                Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Your account needs admin approval before full access.',
                        style: TextStyle(color: AppColors.info, fontSize: 12))),
                    ])),
              ])),
            ),
          ]),
        ),
      ),
    );
  }
}
'@

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " Splash screen + UI polish done!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press 'r' in Flutter terminal to hot reload" -ForegroundColor Cyan
Write-Host "Or press 'R' for full restart (recommended)" -ForegroundColor Cyan
