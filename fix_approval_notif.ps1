function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $path" -ForegroundColor Cyan
}

# ── 1. Waiting for Approval Screen ───────────────────────────────────────────
$waiting = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$waiting += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$waiting += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$waiting += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$waiting += [System.Environment]::NewLine
$waiting += "class WaitingApprovalScreen extends ConsumerWidget {" + [System.Environment]::NewLine
$waiting += "  const WaitingApprovalScreen({super.key});" + [System.Environment]::NewLine
$waiting += [System.Environment]::NewLine
$waiting += "  @override" + [System.Environment]::NewLine
$waiting += "  Widget build(BuildContext context, WidgetRef ref) {" + [System.Environment]::NewLine
$waiting += "    final user = ref.watch(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$waiting += [System.Environment]::NewLine
$waiting += "    return Scaffold(" + [System.Environment]::NewLine
$waiting += "      backgroundColor: AppColors.surface," + [System.Environment]::NewLine
$waiting += "      body: SafeArea(child: Padding(padding: const EdgeInsets.all(32)," + [System.Environment]::NewLine
$waiting += "        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [" + [System.Environment]::NewLine
$waiting += "          Container(width: 100, height: 100," + [System.Environment]::NewLine
$waiting += "            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24))," + [System.Environment]::NewLine
$waiting += "            child: const Icon(Icons.music_note, size: 52, color: Colors.white))," + [System.Environment]::NewLine
$waiting += "          const SizedBox(height: 32)," + [System.Environment]::NewLine
$waiting += "          const Text('Account Pending Approval'," + [System.Environment]::NewLine
$waiting += "            textAlign: TextAlign.center," + [System.Environment]::NewLine
$waiting += "            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary))," + [System.Environment]::NewLine
$waiting += "          const SizedBox(height: 16)," + [System.Environment]::NewLine
$waiting += "          if (user != null) ..." + [System.Environment]::NewLine
$waiting += "            [Text('Welcome, ' + user.name + '!'," + [System.Environment]::NewLine
$waiting += "              textAlign: TextAlign.center," + [System.Environment]::NewLine
$waiting += "              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary))," + [System.Environment]::NewLine
$waiting += "            const SizedBox(height: 8)]," + [System.Environment]::NewLine
$waiting += "          const Text(" + [System.Environment]::NewLine
$waiting += "            'Your registration is complete! The choir leader will review and approve your account shortly.\n\nYou will be able to access the app once approved.'," + [System.Environment]::NewLine
$waiting += "            textAlign: TextAlign.center," + [System.Environment]::NewLine
$waiting += "            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6))," + [System.Environment]::NewLine
$waiting += "          const SizedBox(height: 32)," + [System.Environment]::NewLine
$waiting += "          Container(padding: const EdgeInsets.all(16)," + [System.Environment]::NewLine
$waiting += "            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)," + [System.Environment]::NewLine
$waiting += "              border: Border.all(color: AppColors.divider.withOpacity(0.5)))," + [System.Environment]::NewLine
$waiting += "            child: const Column(children: [" + [System.Environment]::NewLine
$waiting += "              Row(children: [" + [System.Environment]::NewLine
$waiting += "                Icon(Icons.check_circle, color: AppColors.success, size: 20)," + [System.Environment]::NewLine
$waiting += "                SizedBox(width: 10)," + [System.Environment]::NewLine
$waiting += "                Expanded(child: Text('Registration submitted', style: TextStyle(fontWeight: FontWeight.w500)))," + [System.Environment]::NewLine
$waiting += "              ])," + [System.Environment]::NewLine
$waiting += "              SizedBox(height: 12)," + [System.Environment]::NewLine
$waiting += "              Row(children: [" + [System.Environment]::NewLine
$waiting += "                Icon(Icons.hourglass_empty, color: AppColors.warning, size: 20)," + [System.Environment]::NewLine
$waiting += "                SizedBox(width: 10)," + [System.Environment]::NewLine
$waiting += "                Expanded(child: Text('Waiting for admin approval', style: TextStyle(fontWeight: FontWeight.w500)))," + [System.Environment]::NewLine
$waiting += "              ])," + [System.Environment]::NewLine
$waiting += "              SizedBox(height: 12)," + [System.Environment]::NewLine
$waiting += "              Row(children: [" + [System.Environment]::NewLine
$waiting += "                Icon(Icons.lock_open, color: AppColors.textHint, size: 20)," + [System.Environment]::NewLine
$waiting += "                SizedBox(width: 10)," + [System.Environment]::NewLine
$waiting += "                Expanded(child: Text('Access granted after approval', style: TextStyle(color: AppColors.textHint)))," + [System.Environment]::NewLine
$waiting += "              ])," + [System.Environment]::NewLine
$waiting += "            ]))," + [System.Environment]::NewLine
$waiting += "          const SizedBox(height: 32)," + [System.Environment]::NewLine
$waiting += "          OutlinedButton.icon(" + [System.Environment]::NewLine
$waiting += "            onPressed: () => ref.read(authServiceProvider).signOut()," + [System.Environment]::NewLine
$waiting += "            icon: const Icon(Icons.logout)," + [System.Environment]::NewLine
$waiting += "            label: const Text('Sign Out')," + [System.Environment]::NewLine
$waiting += "            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)))," + [System.Environment]::NewLine
$waiting += "        ])))," + [System.Environment]::NewLine
$waiting += "    );" + [System.Environment]::NewLine
$waiting += "  }" + [System.Environment]::NewLine
$waiting += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\features\auth\waiting_approval_screen.dart", $waiting, [System.Text.Encoding]::UTF8)
Write-Host "  created: waiting_approval_screen.dart" -ForegroundColor Cyan

# ── 2. Updated Router with approval gate ─────────────────────────────────────
$router = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$router += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$router += "import 'package:go_router/go_router.dart';" + [System.Environment]::NewLine
$router += "import '../providers/providers.dart';" + [System.Environment]::NewLine
$router += "import '../features/splash/splash_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/auth/login_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/auth/register_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/auth/waiting_approval_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/home/home_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/schedule/schedule_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/admin/admin_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/checkin/checkin_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/attendance/attendance_history_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/music/music_library_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/quiet_time/quiet_time_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/profile/profile_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/directory/directory_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/announcements/announcements_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/testimonies/testimonies_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/shoutouts/shoutouts_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/polls/polls_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/suggestions/suggestion_box_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/badges/badges_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/leaderboard/leaderboard_screen.dart';" + [System.Environment]::NewLine
$router += "import '../features/gallery/gallery_screen.dart';" + [System.Environment]::NewLine
$router += "import '../shared/widgets/main_shell.dart';" + [System.Environment]::NewLine
$router += [System.Environment]::NewLine
$router += "final routerProvider = Provider<GoRouter>((ref) {" + [System.Environment]::NewLine
$router += "  final authState = ref.watch(authStateProvider);" + [System.Environment]::NewLine
$router += "  final userAsync = ref.watch(currentUserProvider);" + [System.Environment]::NewLine
$router += [System.Environment]::NewLine
$router += "  return GoRouter(initialLocation: '/splash'," + [System.Environment]::NewLine
$router += "    redirect: (context, state) {" + [System.Environment]::NewLine
$router += "      final isLoggedIn = authState.valueOrNull != null;" + [System.Environment]::NewLine
$router += "      final user = userAsync.valueOrNull;" + [System.Environment]::NewLine
$router += "      final loc = state.matchedLocation;" + [System.Environment]::NewLine
$router += "      final isAuthRoute = loc == '/login' || loc == '/register';" + [System.Environment]::NewLine
$router += "      final isWaiting = loc == '/waiting-approval';" + [System.Environment]::NewLine
$router += "      final isSplash = loc == '/splash';" + [System.Environment]::NewLine
$router += [System.Environment]::NewLine
$router += "      if (!isLoggedIn && !isAuthRoute && !isSplash) return '/login';" + [System.Environment]::NewLine
$router += "      if (isLoggedIn && isAuthRoute) {" + [System.Environment]::NewLine
$router += "        if (user != null && !user.isApproved) return '/waiting-approval';" + [System.Environment]::NewLine
$router += "        return '/home';" + [System.Environment]::NewLine
$router += "      }" + [System.Environment]::NewLine
$router += "      if (isLoggedIn && user != null && !user.isApproved && !isWaiting && !isSplash) {" + [System.Environment]::NewLine
$router += "        return '/waiting-approval';" + [System.Environment]::NewLine
$router += "      }" + [System.Environment]::NewLine
$router += "      if (isLoggedIn && user != null && user.isApproved && isWaiting) {" + [System.Environment]::NewLine
$router += "        return '/home';" + [System.Environment]::NewLine
$router += "      }" + [System.Environment]::NewLine
$router += "      return null;" + [System.Environment]::NewLine
$router += "    }," + [System.Environment]::NewLine
$router += "    routes: [" + [System.Environment]::NewLine
$router += "      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/login', builder: (_, __) => const LoginScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/waiting-approval', builder: (_, __) => const WaitingApprovalScreen())," + [System.Environment]::NewLine
$router += "      ShellRoute(builder: (c, s, child) => MainShell(child: child), routes: [" + [System.Environment]::NewLine
$router += "        GoRoute(path: '/home', builder: (_, __) => const HomeScreen())," + [System.Environment]::NewLine
$router += "        GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen())," + [System.Environment]::NewLine
$router += "        GoRoute(path: '/communication', builder: (_, __) => const _UC())," + [System.Environment]::NewLine
$router += "        GoRoute(path: '/admin', builder: (_, __) => const AdminScreen())," + [System.Environment]::NewLine
$router += "      ])," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/checkin', builder: (_, __) => const CheckInScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceHistoryScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/music', builder: (_, __) => const MusicLibraryScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/quiet-time', builder: (_, __) => const QuietTimeScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/directory', builder: (_, __) => const DirectoryScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/testimonies', builder: (_, __) => const TestimoniesScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/shoutouts', builder: (_, __) => const ShoutoutsScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/polls', builder: (_, __) => const PollsScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/suggestions', builder: (_, __) => const SuggestionBoxScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/badges', builder: (_, __) => const BadgesScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen())," + [System.Environment]::NewLine
$router += "      GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen())," + [System.Environment]::NewLine
$router += "    ]);" + [System.Environment]::NewLine
$router += "});" + [System.Environment]::NewLine
$router += [System.Environment]::NewLine
$router += "class _UC extends StatelessWidget {" + [System.Environment]::NewLine
$router += "  const _UC();" + [System.Environment]::NewLine
$router += "  @override" + [System.Environment]::NewLine
$router += "  Widget build(BuildContext context) => Scaffold(" + [System.Environment]::NewLine
$router += "    appBar: AppBar(title: const Text('Communication'))," + [System.Environment]::NewLine
$router += "    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [" + [System.Environment]::NewLine
$router += "      Icon(Icons.construction, size: 80, color: Colors.orange.shade400)," + [System.Environment]::NewLine
$router += "      const SizedBox(height: 24)," + [System.Environment]::NewLine
$router += "      Text('Under Construction', style: Theme.of(context).textTheme.headlineMedium)," + [System.Environment]::NewLine
$router += "      const SizedBox(height: 12)," + [System.Environment]::NewLine
$router += "      const Text('Group chat coming soon!', textAlign: TextAlign.center)," + [System.Environment]::NewLine
$router += "    ])));" + [System.Environment]::NewLine
$router += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\router\router.dart", $router, [System.Text.Encoding]::UTF8)
Write-Host "  updated: router.dart with approval gate" -ForegroundColor Cyan

# ── 3. Admin notification provider ───────────────────────────────────────────
$notifProvider = "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$notifProvider += "import 'package:cloud_firestore/cloud_firestore.dart';" + [System.Environment]::NewLine
$notifProvider += [System.Environment]::NewLine
$notifProvider += "// Counts of unread items for admin notifications" + [System.Environment]::NewLine
$notifProvider += "final pendingMembersCountProvider = StreamProvider<int>((ref) {" + [System.Environment]::NewLine
$notifProvider += "  return FirebaseFirestore.instance.collection('users')" + [System.Environment]::NewLine
$notifProvider += "    .where('isApproved', isEqualTo: false)" + [System.Environment]::NewLine
$notifProvider += "    .snapshots().map((s) => s.docs.length);" + [System.Environment]::NewLine
$notifProvider += "});" + [System.Environment]::NewLine
$notifProvider += [System.Environment]::NewLine
$notifProvider += "final unreadSuggestionsCountProvider = StreamProvider<int>((ref) {" + [System.Environment]::NewLine
$notifProvider += "  return FirebaseFirestore.instance.collection('suggestions')" + [System.Environment]::NewLine
$notifProvider += "    .where('isRead', isEqualTo: false)" + [System.Environment]::NewLine
$notifProvider += "    .snapshots().map((s) => s.docs.length);" + [System.Environment]::NewLine
$notifProvider += "});" + [System.Environment]::NewLine
$notifProvider += [System.Environment]::NewLine
$notifProvider += "final pendingTestimoniesCountProvider = StreamProvider<int>((ref) {" + [System.Environment]::NewLine
$notifProvider += "  return FirebaseFirestore.instance.collection('testimonies')" + [System.Environment]::NewLine
$notifProvider += "    .where('isApproved', isEqualTo: false)" + [System.Environment]::NewLine
$notifProvider += "    .snapshots().map((s) => s.docs.length);" + [System.Environment]::NewLine
$notifProvider += "});" + [System.Environment]::NewLine
$notifProvider += [System.Environment]::NewLine
$notifProvider += "final totalAdminNotificationsProvider = StreamProvider<int>((ref) {" + [System.Environment]::NewLine
$notifProvider += "  final pending = ref.watch(pendingMembersCountProvider).valueOrNull ?? 0;" + [System.Environment]::NewLine
$notifProvider += "  final suggestions = ref.watch(unreadSuggestionsCountProvider).valueOrNull ?? 0;" + [System.Environment]::NewLine
$notifProvider += "  final testimonies = ref.watch(pendingTestimoniesCountProvider).valueOrNull ?? 0;" + [System.Environment]::NewLine
$notifProvider += "  return Stream.value(pending + suggestions + testimonies);" + [System.Environment]::NewLine
$notifProvider += "});" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\providers\notification_providers.dart", $notifProvider, [System.Text.Encoding]::UTF8)
Write-Host "  created: notification_providers.dart" -ForegroundColor Cyan

# ── 4. Updated Main Shell with notification badges ────────────────────────────
$shell = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$shell += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$shell += "import 'package:go_router/go_router.dart';" + [System.Environment]::NewLine
$shell += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$shell += "import '../../providers/notification_providers.dart';" + [System.Environment]::NewLine
$shell += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "class MainShell extends ConsumerWidget {" + [System.Environment]::NewLine
$shell += "  final Widget child;" + [System.Environment]::NewLine
$shell += "  const MainShell({super.key, required this.child});" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "  int _locationToIndex(String location) {" + [System.Environment]::NewLine
$shell += "    if (location.startsWith('/schedule')) return 1;" + [System.Environment]::NewLine
$shell += "    if (location.startsWith('/communication')) return 2;" + [System.Environment]::NewLine
$shell += "    if (location.startsWith('/admin')) return 3;" + [System.Environment]::NewLine
$shell += "    return 0;" + [System.Environment]::NewLine
$shell += "  }" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "  @override" + [System.Environment]::NewLine
$shell += "  Widget build(BuildContext context, WidgetRef ref) {" + [System.Environment]::NewLine
$shell += "    final location = GoRouterState.of(context).matchedLocation;" + [System.Environment]::NewLine
$shell += "    final currentIndex = _locationToIndex(location);" + [System.Environment]::NewLine
$shell += "    final user = ref.watch(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$shell += "    final adminNotifCount = user?.isAdmin == true" + [System.Environment]::NewLine
$shell += "        ? ref.watch(totalAdminNotificationsProvider).valueOrNull ?? 0" + [System.Environment]::NewLine
$shell += "        : 0;" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "    return Scaffold(" + [System.Environment]::NewLine
$shell += "      body: child," + [System.Environment]::NewLine
$shell += "      bottomNavigationBar: Container(" + [System.Environment]::NewLine
$shell += "        decoration: BoxDecoration(color: Colors.white," + [System.Environment]::NewLine
$shell += "          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))])," + [System.Environment]::NewLine
$shell += "        child: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)," + [System.Environment]::NewLine
$shell += "          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [" + [System.Environment]::NewLine
$shell += "            _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0, current: currentIndex, onTap: () => context.go('/home'))," + [System.Environment]::NewLine
$shell += "            _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Schedule', index: 1, current: currentIndex, onTap: () => context.go('/schedule'))," + [System.Environment]::NewLine
$shell += "            _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Updates', index: 2, current: currentIndex, onTap: () => context.go('/communication'))," + [System.Environment]::NewLine
$shell += "            _NavItemBadge(" + [System.Environment]::NewLine
$shell += "              icon: user?.isAdmin == true ? Icons.admin_panel_settings_outlined : Icons.person_outline," + [System.Environment]::NewLine
$shell += "              activeIcon: user?.isAdmin == true ? Icons.admin_panel_settings : Icons.person," + [System.Environment]::NewLine
$shell += "              label: user?.isAdmin == true ? 'Admin' : 'Profile'," + [System.Environment]::NewLine
$shell += "              index: 3, current: currentIndex," + [System.Environment]::NewLine
$shell += "              badgeCount: adminNotifCount," + [System.Environment]::NewLine
$shell += "              onTap: () => context.go('/admin'))," + [System.Environment]::NewLine
$shell += "          ])))," + [System.Environment]::NewLine
$shell += "      )," + [System.Environment]::NewLine
$shell += "    );" + [System.Environment]::NewLine
$shell += "  }" + [System.Environment]::NewLine
$shell += "}" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "class _NavItem extends StatelessWidget {" + [System.Environment]::NewLine
$shell += "  final IconData icon, activeIcon;" + [System.Environment]::NewLine
$shell += "  final String label;" + [System.Environment]::NewLine
$shell += "  final int index, current;" + [System.Environment]::NewLine
$shell += "  final VoidCallback onTap;" + [System.Environment]::NewLine
$shell += "  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap});" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "  @override" + [System.Environment]::NewLine
$shell += "  Widget build(BuildContext context) {" + [System.Environment]::NewLine
$shell += "    final isActive = index == current;" + [System.Environment]::NewLine
$shell += "    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque," + [System.Environment]::NewLine
$shell += "      child: AnimatedContainer(duration: const Duration(milliseconds: 200)," + [System.Environment]::NewLine
$shell += "        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)," + [System.Environment]::NewLine
$shell += "        decoration: BoxDecoration(color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(12))," + [System.Environment]::NewLine
$shell += "        child: Column(mainAxisSize: MainAxisSize.min, children: [" + [System.Environment]::NewLine
$shell += "          Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : AppColors.textHint, size: 24)," + [System.Environment]::NewLine
$shell += "          const SizedBox(height: 2)," + [System.ême]::NewLine
$shell += "          Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? AppColors.primary : AppColors.textHint))," + [System.Environment]::NewLine
$shell += "        ])));" + [System.Environment]::NewLine
$shell += "  }" + [System.Environment]::NewLine
$shell += "}" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "class _NavItemBadge extends StatelessWidget {" + [System.Environment]::NewLine
$shell += "  final IconData icon, activeIcon;" + [System.Environment]::NewLine
$shell += "  final String label;" + [System.Environment]::NewLine
$shell += "  final int index, current, badgeCount;" + [System.Environment]::NewLine
$shell += "  final VoidCallback onTap;" + [System.Environment]::NewLine
$shell += "  const _NavItemBadge({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.badgeCount, required this.onTap});" + [System.Environment]::NewLine
$shell += [System.Environment]::NewLine
$shell += "  @override" + [System.Environment]::NewLine
$shell += "  Widget build(BuildContext context) {" + [System.Environment]::NewLine
$shell += "    final isActive = index == current;" + [System.Environment]::NewLine
$shell += "    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque," + [System.Environment]::NewLine
$shell += "      child: AnimatedContainer(duration: const Duration(milliseconds: 200)," + [System.Environment]::NewLine
$shell += "        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)," + [System.Environment]::NewLine
$shell += "        decoration: BoxDecoration(color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(12))," + [System.Environment]::NewLine
$shell += "        child: Column(mainAxisSize: MainAxisSize.min, children: [" + [System.Environment]::NewLine
$shell += "          Stack(clipBehavior: Clip.none, children: [" + [System.Environment]::NewLine
$shell += "            Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : AppColors.textHint, size: 24)," + [System.Environment]::NewLine
$shell += "            if (badgeCount > 0) Positioned(right: -6, top: -4," + [System.Environment]::NewLine
$shell += "              child: Container(padding: const EdgeInsets.all(3)," + [System.Environment]::NewLine
$shell += "                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)," + [System.Environment]::NewLine
$shell += "                constraints: const BoxConstraints(minWidth: 16, minHeight: 16)," + [System.Environment]::NewLine
$shell += "                child: Text(badgeCount > 99 ? '99+' : badgeCount.toString()," + [System.Environment]::NewLine
$shell += "                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)," + [System.Environment]::NewLine
$shell += "                  textAlign: TextAlign.center)))," + [System.Environment]::NewLine
$shell += "          ])," + [System.Environment]::NewLine
$shell += "          const SizedBox(height: 2)," + [System.Environment]::NewLine
$shell += "          Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? AppColors.primary : AppColors.textHint))," + [System.Environment]::NewLine
$shell += "        ])));" + [System.Environment]::NewLine
$shell += "  }" + [System.Environment]::NewLine
$shell += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\shared\widgets\main_shell.dart", $shell, [System.Text.Encoding]::UTF8)
Write-Host "  updated: main_shell.dart with notification badges" -ForegroundColor Cyan

# ── 5. Updated Admin screen with notification sections ────────────────────────
# Add approve testimonies section to admin quick actions
$adminNotifSection = "import 'package:cloud_firestore/cloud_firestore.dart';" + [System.Environment]::NewLine
$adminNotifSection += "import '../../providers/notification_providers.dart';" + [System.Environment]::NewLine

# Patch admin screen to show pending counts on action buttons
$adminContent = [System.IO.File]::ReadAllText("lib\features\admin\admin_screen.dart", [System.Text.Encoding]::UTF8)
if (-not $adminContent.Contains("notification_providers")) {
    $adminContent = $adminContent.Replace(
        "import '../../models/user_model.dart';",
        "import '../../models/user_model.dart';" + [System.Environment]::NewLine + "import '../../providers/notification_providers.dart';"
    )
    [System.IO.File]::WriteAllText("lib\features\admin\admin_screen.dart", $adminContent, [System.Text.Encoding]::UTF8)
    Write-Host "  updated: admin_screen.dart with notification imports" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " Approval gate + notifications done!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Now update Firestore rules:" -ForegroundColor Cyan
Write-Host "  Go to Firebase Console -> Firestore -> Rules" -ForegroundColor White
Write-Host "  Paste the rules from fix_firestore_rules.txt" -ForegroundColor White
Write-Host ""
Write-Host "Press 'R' in Flutter terminal for full restart" -ForegroundColor Yellow
