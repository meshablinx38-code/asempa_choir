$fix = @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final songsAsync = ref.watch(songsProvider(null));
    final rehearsalsAsync = ref.watch(upcomingRehearsalsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asempa Choir'),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data found.'));
          }
          return ListView(padding: const EdgeInsets.all(16), children: [

            // ── Welcome card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                      ? NetworkImage(user.photoUrl!) : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 24, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    Text(
                      user.name.isNotEmpty ? user.name : 'Choir Member',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.voicePart.toUpperCase(),
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Quick Stats ────────────────────────────────────────────────
            Text('Quick Stats', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.check_circle,
                iconColor: AppColors.success,
                value: user.attendanceCount.toString(),
                label: 'Attendance',
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.local_fire_department,
                iconColor: AppColors.warning,
                value: user.streak.toString(),
                label: 'Streak',
              )),
            ]),
            const SizedBox(height: 20),

            // ── Recent Songs ───────────────────────────────────────────────
            songsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (songs) => songs.isEmpty ? const SizedBox() : _SectionCard(
                icon: Icons.music_note,
                title: 'Recent Songs',
                onViewAll: () => context.push('/music'),
                children: songs.take(4).map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: s.artist != null ? Text(s.artist!) : null,
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Upcoming Rehearsals ────────────────────────────────────────
            _SectionCard(
              icon: Icons.calendar_today,
              title: 'Upcoming Rehearsals',
              onViewAll: () => context.push('/schedule'),
              children: rehearsalsAsync.when(
                loading: () => [const Center(child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (r) => r.isEmpty
                    ? [Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No upcoming rehearsals scheduled',
                            style: Theme.of(context).textTheme.bodyMedium))]
                    : r.take(3).map((reh) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(reh.title),
                        subtitle: Text(DateFormat('EEE, MMM d • h:mm a').format(reh.dateTime)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                      )).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Announcements ──────────────────────────────────────────────
            _SectionCard(
              icon: Icons.campaign,
              title: 'Recent Announcements',
              children: announcementsAsync.when(
                loading: () => [const Center(child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (items) => items.isEmpty
                    ? [Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No announcements',
                            style: Theme.of(context).textTheme.bodyMedium))]
                    : items.take(3).map((a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.campaign, size: 20,
                              color: AppColors.textSecondary),
                        ),
                        title: Text(a.title),
                        subtitle: Text(DateFormat('d MMM y').format(a.date)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                      )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── More Features ──────────────────────────────────────────────
            Text('More Features', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _Feature(icon: Icons.group, label: 'Directory',
                color: Colors.blue.shade100, iconColor: Colors.blue,
                onTap: () => context.push('/directory')),
            _Feature(icon: Icons.person, label: 'Profile',
                color: Colors.purple.shade100, iconColor: Colors.purple,
                onTap: () => context.push('/profile')),
            _Feature(icon: Icons.menu_book, label: 'Quiet Time',
                color: Colors.teal.shade100, iconColor: Colors.teal,
                onTap: () => context.push('/quiet-time')),
            _Feature(icon: Icons.library_music, label: 'Music',
                color: Colors.orange.shade100, iconColor: Colors.orange,
                onTap: () => context.push('/music')),
            _Feature(icon: Icons.qr_code_scanner, label: 'Check In',
                color: Colors.green.shade100, iconColor: Colors.green,
                onTap: () => context.push('/checkin')),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value, label;
  const _StatCard({required this.icon, required this.iconColor,
      required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider.withOpacity(0.5)),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: iconColor)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final VoidCallback? onViewAll;
  const _SectionCard({required this.icon, required this.title,
      required this.children, this.onViewAll});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider.withOpacity(0.5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('See all')),
      ]),
      ...children,
    ]),
  );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, iconColor;
  final VoidCallback onTap;
  const _Feature({required this.icon, required this.label,
      required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    ),
  );
}
'@

[System.IO.File]::WriteAllText("lib\features\home\home_screen.dart", $fix, [System.Text.Encoding]::UTF8)
Write-Host "home_screen.dart fixed!" -ForegroundColor Green
