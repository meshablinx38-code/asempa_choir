import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/safe_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final songsAsync = ref.watch(songsProvider);
    final rehearsalsAsync = ref.watch(upcomingRehearsalsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Asempa Choir'),
          actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})]),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('No user data.'));
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                SafeAvatar(photoUrl: user.photoUrl, name: user.name, voicePart: user.voicePart, radius: 30, fontSize: 24),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  Text(user.name.isNotEmpty ? user.name : 'Choir Member', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(user.voicePart.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            // Quick Stats
            Text('Quick Stats', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard(icon: Icons.check_circle, iconColor: AppColors.success, value: user.attendanceCount.toString(), label: 'Attendance', onTap: () => context.push('/attendance'))),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.local_fire_department, iconColor: AppColors.warning, value: user.streak.toString(), label: 'Streak', onTap: () => context.push('/badges'))),
            ]),
            const SizedBox(height: 20),

            // Songs
            songsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (songs) => songs.isEmpty
                  ? const SizedBox()
                  : _SectionCard(
                      icon: Icons.music_note,
                      title: 'Recent Songs',
                      onViewAll: () => context.push('/music'),
                      children: songs.take(3).map((s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.title, style: Theme.of(context).textTheme.titleMedium),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 16),

            // Rehearsals
            _SectionCard(
              icon: Icons.calendar_today,
              title: 'Upcoming Rehearsals',
              onViewAll: () => context.push('/schedule'),
              children: rehearsalsAsync.when(
                loading: () => [const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (r) => r.isEmpty
                    ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No upcoming rehearsals', style: Theme.of(context).textTheme.bodyMedium))]
                    : r.take(3).map((reh) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(reh.title ?? 'Rehearsal'),
                        subtitle: Text(DateFormat('EEE, MMM d | h:mm a').format(reh.date)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 16),

            // Announcements
            _SectionCard(
              icon: Icons.campaign,
              title: 'Recent Announcements',
              children: announcementsAsync.when(
                loading: () => [const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (items) => items.isEmpty
                    ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No announcements', style: Theme.of(context).textTheme.bodyMedium))]
                    : items.take(3).map((a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.campaign, size: 20, color: AppColors.textSecondary)),
                        title: Text(a.title),
                        subtitle: Text(DateFormat('d MMM y').format(a.createdAt)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 20),

            // Features Grid
            Text('Features', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                _GridFeature(icon: Icons.person, label: 'Profile', color: Colors.purple.shade100, iconColor: Colors.purple, onTap: () => context.push('/profile')),
                _GridFeature(icon: Icons.group, label: 'Directory', color: Colors.blue.shade100, iconColor: Colors.blue, onTap: () => context.push('/directory')),
                _GridFeature(icon: Icons.menu_book, label: 'Quiet Time', color: Colors.teal.shade100, iconColor: Colors.teal, onTap: () => context.push('/quiet-time')),
                _GridFeature(icon: Icons.library_music, label: 'Music', color: Colors.orange.shade100, iconColor: Colors.orange, onTap: () => context.push('/music')),
                _GridFeature(icon: Icons.qr_code_scanner, label: 'Check In', color: Colors.green.shade100, iconColor: Colors.green, onTap: () => context.push('/checkin')),
                _GridFeature(icon: Icons.workspace_premium, label: 'Badges', color: Colors.amber.shade100, iconColor: Colors.amber, onTap: () => context.push('/badges')),
                _GridFeature(icon: Icons.leaderboard, label: 'Leaderboard', color: Colors.red.shade100, iconColor: Colors.red, onTap: () => context.push('/leaderboard')),
                _GridFeature(icon: Icons.volunteer_activism, label: 'Testimonies', color: Colors.pink.shade100, iconColor: Colors.pink, onTap: () => context.push('/testimonies')),
                _GridFeature(icon: Icons.celebration, label: 'Shoutouts', color: Colors.deepPurple.shade100, iconColor: Colors.deepPurple, onTap: () => context.push('/shoutouts')),
                _GridFeature(icon: Icons.poll, label: 'Polls', color: Colors.cyan.shade100, iconColor: Colors.cyan, onTap: () => context.push('/polls')),
                _GridFeature(icon: Icons.lightbulb_outline, label: 'Suggestions', color: Colors.lime.shade100, iconColor: Colors.lime.shade700, onTap: () => context.push('/suggestions')),
                _GridFeature(icon: Icons.photo_library, label: 'Gallery', color: Colors.indigo.shade100, iconColor: Colors.indigo, onTap: () => context.push('/gallery')),
              ]),
            const SizedBox(height: 24),
          ]);
        }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value, label;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withOpacity(0.5))),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: iconColor)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ));
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final VoidCallback? onViewAll;

  const _SectionCard({required this.icon, required this.title, required this.children, this.onViewAll});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withOpacity(0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: AppColors.textSecondary)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('See all')),
        ]),
        ...children,
      ]));
}

class _GridFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, iconColor;
  final VoidCallback onTap;

  const _GridFeature({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider.withOpacity(0.5))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ]),
      ));
}