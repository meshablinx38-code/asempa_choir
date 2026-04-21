import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/waiting_approval_screen.dart';
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
import '../features/testimonies/testimonies_screen.dart';
import '../features/shoutouts/shoutouts_screen.dart';
import '../features/polls/polls_screen.dart';
import '../features/suggestions/suggestion_box_screen.dart';
import '../features/badges/badges_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final user = userAsync.valueOrNull;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isWaiting = loc == '/waiting-approval';
      final isSplash = loc == '/splash';

      if (!isLoggedIn && !isAuthRoute && !isSplash) return '/login';
      if (isLoggedIn && isAuthRoute) {
        if (user != null && !user.isApproved) return '/waiting-approval';
        return '/home';
      }
      if (isLoggedIn && user != null && !user.isApproved && !isWaiting && !isSplash) {
        return '/waiting-approval';
      }
      if (isLoggedIn && user != null && user.isApproved && isWaiting) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/waiting-approval', builder: (_, __) => const WaitingApprovalScreen()),
      ShellRoute(builder: (c, s, child) => MainShell(child: child), routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
        GoRoute(path: '/communication', builder: (_, __) => const _UC()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      ]),
      GoRoute(path: '/checkin', builder: (_, __) => const CheckInScreen()),
      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceHistoryScreen()),
      GoRoute(path: '/music', builder: (_, __) => const MusicLibraryScreen()),
      GoRoute(path: '/quiet-time', builder: (_, __) => const QuietTimeScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/directory', builder: (_, __) => const DirectoryScreen()),
      GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsScreen()),
      GoRoute(path: '/testimonies', builder: (_, __) => const TestimoniesScreen()),
      GoRoute(path: '/shoutouts', builder: (_, __) => const ShoutoutsScreen()),
      GoRoute(path: '/polls', builder: (_, __) => const PollsScreen()),
      GoRoute(path: '/suggestions', builder: (_, __) => const SuggestionBoxScreen()),
      GoRoute(path: '/badges', builder: (_, __) => const BadgesScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen()),
    ]);
});

class _UC extends StatelessWidget {
  const _UC();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Communication')),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.construction, size: 80, color: Colors.orange.shade400),
      const SizedBox(height: 24),
      Text('Under Construction', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Text('Group chat coming soon!', textAlign: TextAlign.center),
    ])));
}
