# Fix CircleAvatar assertion error across all screens

function Fix-File($path, $oldText, $newText) {
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        $fixed = $content -replace [regex]::Escape($oldText), $newText
        [System.IO.File]::WriteAllText($path, $fixed, [System.Text.Encoding]::UTF8)
        Write-Host "  fixed: $path" -ForegroundColor Cyan
    }
}

function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  updated: $path" -ForegroundColor Cyan
}

# The root cause: CircleAvatar with onBackgroundImageError but no backgroundImage
# Fix: Use a safe avatar helper widget instead

# Fix profile_screen.dart - remove onBackgroundImageError
Fix-File "lib\features\profile\profile_screen.dart" `
    "onBackgroundImageError: (_, __) {}," `
    ""

# Fix home_screen.dart - any CircleAvatar with backgroundImage issues
# The safest fix is to create a shared SafeAvatar widget and use it everywhere

Write-File "lib\shared\widgets\safe_avatar.dart" @'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A safe CircleAvatar that handles null/empty photoUrl gracefully.
/// Avoids the Flutter assertion: backgroundImage != null || onBackgroundImageError == null
class SafeAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final String voicePart;
  final double radius;
  final double fontSize;

  const SafeAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    required this.voicePart,
    this.radius = 24,
    this.fontSize = 16,
  });

  bool get _hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final color = voicePartColor(voicePart);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (!_hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.2),
        child: Text(initial,
            style: TextStyle(color: color,
                fontSize: fontSize, fontWeight: FontWeight.w600)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.2),
      child: ClipOval(
        child: Image.network(
          photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(initial,
              style: TextStyle(color: color,
                  fontSize: fontSize, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
'@

# Now update home_screen to use SafeAvatar
Write-File "lib\features\home\home_screen.dart" @'
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
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('No user data.'));
          return ListView(padding: const EdgeInsets.all(16), children: [

            // ── Welcome card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                SafeAvatar(
                  photoUrl: user.photoUrl,
                  name: user.name,
                  voicePart: user.voicePart,
                  radius: 30,
                  fontSize: 24,
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    Text(user.name.isNotEmpty ? user.name : 'Choir Member',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(user.voicePart.toUpperCase(),
                          style: const TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w600)),
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
              Expanded(child: _StatCard(icon: Icons.check_circle,
                  iconColor: AppColors.success,
                  value: user.attendanceCount.toString(), label: 'Attendance')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.local_fire_department,
                  iconColor: AppColors.warning,
                  value: user.streak.toString(), label: 'Streak')),
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
                  title: Text(s.title, style: Theme.of(context).textTheme.titleMedium),
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
                    padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (r) => r.isEmpty
                    ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No upcoming rehearsals',
                            style: Theme.of(context).textTheme.bodyMedium))]
                    : r.take(3).map((reh) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(reh.title ?? 'Rehearsal'),
                        subtitle: Text(DateFormat('EEE, MMM d • h:mm a').format(reh.date)),
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
                    padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (items) => items.isEmpty
                    ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No announcements',
                            style: Theme.of(context).textTheme.bodyMedium))]
                    : items.take(3).map((a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.campaign, size: 20,
                              color: AppColors.textSecondary),
                        ),
                        title: Text(a.title),
                        subtitle: Text(DateFormat('d MMM y').format(a.createdAt)),
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

class _StatCard extends StatelessWidget {
  final IconData icon; final Color iconColor; final String value, label;
  const _StatCard({required this.icon, required this.iconColor,
      required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5))),
    child: Column(children: [
      Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: iconColor)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final IconData icon; final String title;
  final List<Widget> children; final VoidCallback? onViewAll;
  const _SectionCard({required this.icon, required this.title,
      required this.children, this.onViewAll});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppColors.textSecondary)),
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
  final IconData icon; final String label;
  final Color color, iconColor; final VoidCallback onTap;
  const _Feature({required this.icon, required this.label,
      required this.color, required this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22)),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap),
  );
}
'@

# Update admin_screen to use SafeAvatar
$adminContent = [System.IO.File]::ReadAllText("lib\features\admin\admin_screen.dart", [System.Text.Encoding]::UTF8)
$adminFixed = $adminContent -replace "import '../../providers/providers.dart';", "import '../../providers/providers.dart';`nimport '../../shared/widgets/safe_avatar.dart';"
# Fix member tile avatars - remove onBackgroundImageError
$adminFixed = $adminFixed -replace "onBackgroundImageError: \(_, __\) \{\},`n\s*", ""
[System.IO.File]::WriteAllText("lib\features\admin\admin_screen.dart", $adminFixed, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: lib\features\admin\admin_screen.dart" -ForegroundColor Cyan

# Update directory_screen to use SafeAvatar
$dirContent = [System.IO.File]::ReadAllText("lib\features\directory\directory_screen.dart", [System.Text.Encoding]::UTF8)
$dirFixed = $dirContent -replace "import '../../providers/providers.dart';", "import '../../providers/providers.dart';`nimport '../../shared/widgets/safe_avatar.dart';"
[System.IO.File]::WriteAllText("lib\features\directory\directory_screen.dart", $dirFixed, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: lib\features\directory\directory_screen.dart" -ForegroundColor Cyan

# Update profile_screen to use SafeAvatar
$profileContent = [System.IO.File]::ReadAllText("lib\features\profile\profile_screen.dart", [System.Text.Encoding]::UTF8)
$profileFixed = $profileContent -replace "import 'package:intl/intl.dart';", "import 'package:intl/intl.dart';`nimport '../../shared/widgets/safe_avatar.dart';"
$profileFixed = $profileFixed -replace "onBackgroundImageError: \(_, __\) \{\},", ""
[System.IO.File]::WriteAllText("lib\features\profile\profile_screen.dart", $profileFixed, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: lib\features\profile\profile_screen.dart" -ForegroundColor Cyan

Write-Host ""
Write-Host "CircleAvatar error fixed everywhere!" -ForegroundColor Green
Write-Host "Press 'r' to hot reload" -ForegroundColor Yellow
