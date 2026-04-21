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