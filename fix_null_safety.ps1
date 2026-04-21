# Fix null safety issues in home_screen and admin_screen

function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  fixed: $path" -ForegroundColor Cyan
}

# ══════════════════════════════════════════════════════════════════════════════
# Fix home_screen.dart - songsProvider no longer takes a parameter
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\home\home_screen.dart" @'
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
                    ? [Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No upcoming rehearsals scheduled',
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
  final IconData icon;
  final Color iconColor;
  final String value, label;
  const _StatCard({required this.icon, required this.iconColor,
      required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
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
      color: Colors.white, borderRadius: BorderRadius.circular(16),
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

# ══════════════════════════════════════════════════════════════════════════════
# Fix admin_screen.dart - null safety on voicePart and name
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\admin\admin_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Admin access required', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Only choir leaders can access this section.',
              style: Theme.of(context).textTheme.bodyMedium),
        ])),
      );
    }

    final statsAsync = ref.watch(adminStatsProvider);
    final activeSessionAsync = ref.watch(activeSessionProvider);
    final membersAsync = ref.watch(allMembersProvider);
    final quietTimeAsync = ref.watch(quietTimePostsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ── Welcome card ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back,',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              Text(user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Choir Leader',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Overview ───────────────────────────────────────────────────────
        Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
          data: (stats) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            children: [
              _StatTile(value: stats['totalMembers'].toString(),
                  label: 'Total Members', color: AppColors.adminBlue, icon: Icons.people),
              _StatTile(value: stats['completeProfiles'].toString(),
                  label: 'Complete Profiles', color: AppColors.adminGreen, icon: Icons.check_circle),
              _StatTile(value: stats['pendingSetup'].toString(),
                  label: 'Pending Approval', color: AppColors.adminOrange, icon: Icons.pending),
              _StatTile(value: stats['activeSessions'].toString(),
                  label: 'Active Sessions', color: AppColors.adminPurple, icon: Icons.qr_code),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Quick Actions ──────────────────────────────────────────────────
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ActionBtn(label: 'Approve Members', icon: Icons.how_to_reg,
              color: AppColors.adminGreen, onTap: () => _showPendingMembers(context, ref))),
          const SizedBox(width: 12),
          Expanded(child: _ActionBtn(label: 'Announcements', icon: Icons.campaign,
              color: AppColors.adminOrange, onTap: () => context.push('/announcements'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _ActionBtn(label: 'Music Library', icon: Icons.library_music,
              color: Colors.deepPurple, onTap: () => context.push('/music'))),
          const SizedBox(width: 12),
          Expanded(child: _ActionBtn(label: 'Schedule', icon: Icons.calendar_today,
              color: Colors.teal, onTap: () => context.go('/schedule'))),
        ]),
        const SizedBox(height: 20),

        // ── QR Code ────────────────────────────────────────────────────────
        Text('Attendance QR Code', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        _QrSection(activeSessionAsync: activeSessionAsync, ref: ref, adminUid: user.uid),
        const SizedBox(height: 20),

        // ── Members ────────────────────────────────────────────────────────
        Text('Asempa Members', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (members) => Column(
            children: members.map((m) => _MemberTile(member: m, ref: ref)).toList()),
        ),
        const SizedBox(height: 20),

        // ── Quiet Time ─────────────────────────────────────────────────────
        Text('Quiet Time Posts', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        quietTimeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
          data: (posts) => posts.isEmpty
              ? Center(child: Text('No quiet time posts yet.',
                  style: Theme.of(context).textTheme.bodyMedium))
              : Column(children: posts.map((p) => _QtPostCard(post: p)).toList()),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  void _showPendingMembers(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
        builder: (_, scrollCtrl) => Consumer(builder: (_, ref, __) {
          final pendingAsync = ref.watch(pendingMembersProvider);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Pending Approvals',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Expanded(child: pendingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
                data: (members) => members.isEmpty
                    ? const Center(child: Text('No pending approvals'))
                    : ListView(controller: scrollCtrl,
                        children: members.map((m) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?'),
                            ),
                            title: Text(m.name),
                            subtitle: Text('${m.voicePart} • ${m.email}'),
                            trailing: ElevatedButton(
                              onPressed: () => ref.read(firestoreServiceProvider).approveUser(m.uid),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.adminGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 12)),
                              child: const Text('Approve', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        )).toList()),
              )),
            ]),
          );
        }),
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  final AsyncValue<SessionModel?> activeSessionAsync;
  final WidgetRef ref;
  final String adminUid;
  const _QrSection({required this.activeSessionAsync, required this.ref, required this.adminUid});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider.withOpacity(0.5)),
    ),
    child: Column(children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.qr_code, color: Colors.purple, size: 20),
        ),
        const SizedBox(width: 10),
        Text('Attendance QR Code', style: Theme.of(context).textTheme.titleLarge),
      ]),
      const SizedBox(height: 16),
      activeSessionAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const SizedBox(),
        data: (session) => session == null
            ? Column(children: [
                Container(
                  height: 160, width: 160,
                  decoration: BoxDecoration(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, size: 52, color: AppColors.textHint),
                      SizedBox(height: 8),
                      Text('No active session',
                          style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                      Text('Generate a QR code\nto start check-in',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ],
                  )),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(firestoreServiceProvider).createSession(createdBy: adminUid),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Generate QR Code'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 48)),
                ),
              ])
            : Column(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider)),
                  child: QrImageView(data: session.qrCode, size: 180),
                ),
                const SizedBox(height: 12),
                Text(session.label ?? 'Active Session',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  session.expiresAt != null
                      ? 'Expires: ${DateFormat('h:mm a').format(session.expiresAt!)}'
                      : 'No expiry',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${session.checkedInUids.length} member${session.checkedInUids.length == 1 ? '' : 's'} checked in',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.read(firestoreServiceProvider).endSession(session.id),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('End Session'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 48)),
                ),
              ]),
      ),
    ]),
  );
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _StatTile({required this.value, required this.label,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: Colors.white, size: 28),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: Colors.white,
          fontSize: 28, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}

class _MemberTile extends StatelessWidget {
  final UserModel member;
  final WidgetRef ref;
  const _MemberTile({required this.member, required this.ref});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: voicePartColor(member.voicePart).withOpacity(0.2),
        backgroundImage: (member.photoUrl != null && member.photoUrl!.isNotEmpty)
            ? NetworkImage(member.photoUrl!) : null,
        child: (member.photoUrl == null || member.photoUrl!.isEmpty)
            ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(color: voicePartColor(member.voicePart),
                    fontWeight: FontWeight.w600))
            : null,
      ),
      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: voicePartColor(member.voicePart).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(member.voicePart.toUpperCase(),
                style: TextStyle(color: voicePartColor(member.voicePart),
                    fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          if (member.isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.adminOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('ADMIN',
                  style: TextStyle(color: AppColors.adminOrange,
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        const SizedBox(height: 2),
        Text(
          member.lastLoginAt != null
              ? 'Last login: ${DateFormat('MMM d, y').format(member.lastLoginAt!)}'
              : 'Last login: Never',
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ]),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'make_admin') {
            await ref.read(firestoreServiceProvider).updateUserRole(member.uid, UserRole.admin);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.name} is now an admin')));
          } else if (value == 'remove_admin') {
            await ref.read(firestoreServiceProvider).updateUserRole(member.uid, UserRole.member);
          } else if (value == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Remove Member'),
                content: Text('Remove ${member.name} from the choir?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove', style: TextStyle(color: AppColors.error))),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(firestoreServiceProvider).deleteUser(member.uid);
            }
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: member.isAdmin ? 'remove_admin' : 'make_admin',
              child: Text(member.isAdmin ? 'Remove Admin' : 'Make Admin')),
          const PopupMenuItem(value: 'delete',
              child: Text('Remove from Choir', style: TextStyle(color: AppColors.error))),
        ],
      ),
    ),
  );
}

class _QtPostCard extends StatelessWidget {
  final QuietTimePost post;
  const _QtPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final vp = post.voicePart ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: voicePartColor(vp).withOpacity(0.2),
              child: Text(post.fullName.isNotEmpty ? post.fullName[0].toUpperCase() : '?',
                  style: TextStyle(color: voicePartColor(vp), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.isAnonymous ? 'Anonymous' : post.fullName,
                  style: Theme.of(context).textTheme.titleMedium),
              if (vp.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: voicePartColor(vp).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(vp.toUpperCase(),
                      style: TextStyle(color: voicePartColor(vp),
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ])),
            Text(DateFormat('MMM d').format(post.timestamp),
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.bookmark, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text(post.verse, style: const TextStyle(
                  fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),
          Text(post.reflection, style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
    );
  }
}
'@

Write-Host ""
Write-Host "All null safety issues fixed!" -ForegroundColor Green
Write-Host "Press 'r' in Flutter terminal to hot reload" -ForegroundColor Yellow
