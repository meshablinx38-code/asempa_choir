function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $path" -ForegroundColor Cyan
}

# ── polls_screen.dart ─────────────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\features\polls\polls_screen.dart", @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/phase2_models.dart';

final pollsProvider = StreamProvider<List<PollModel>>((ref) {
  return FirebaseFirestore.instance.collection('polls').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(PollModel.fromFirestore).toList());
});

class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pollsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Polls & Surveys')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (polls) => polls.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.poll, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No active polls', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Check back later.', style: Theme.of(context).textTheme.bodyMedium),
              ]))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: polls.length,
                itemBuilder: (_, i) => _PollCard(poll: polls[i], currentUserId: user?.uid ?? '')),
      ),
      floatingActionButton: user?.isAdmin == true
          ? FloatingActionButton.extended(onPressed: () => _showCreate(context, ref, user!.uid),
              icon: const Icon(Icons.add), label: const Text('Create Poll'), backgroundColor: AppColors.primary)
          : null,
    );
  }

  void _showCreate(BuildContext ctx, WidgetRef ref, String uid) {
    final q = TextEditingController();
    final opts = List.generate(4, (i) => TextEditingController(text: i == 0 ? 'Yes' : i == 1 ? 'No' : ''));
    showModalBottomSheet(context: ctx, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (c) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Create Poll', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: q, maxLines: 2, decoration: const InputDecoration(labelText: 'Question', alignLabelWithHint: true)),
            const SizedBox(height: 12),
            ...opts.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8),
                child: TextField(controller: e.value, decoration: InputDecoration(labelText: 'Option \${e.key + 1}\${e.key >= 2 ? " (optional)" : ""}')))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () async {
              if (q.text.isEmpty || opts[0].text.isEmpty || opts[1].text.isEmpty) return;
              final options = [opts[0].text.trim(), opts[1].text.trim(), ...opts.skip(2).map((o) => o.text.trim()).where((t) => t.isNotEmpty)];
              final votes = {for (final o in options) o: <String>[]};
              final poll = PollModel(id: const Uuid().v4(), question: q.text.trim(), createdBy: uid, options: options, votes: votes, createdAt: DateTime.now());
              await FirebaseFirestore.instance.collection('polls').doc(poll.id).set(poll.toFirestore());
              if (c.mounted) Navigator.pop(c);
            }, child: const Text('Publish Poll')),
          ]))));
  }
}

class _PollCard extends StatelessWidget {
  final PollModel poll; final String currentUserId;
  const _PollCard({required this.poll, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    final userVote = poll.userVote(currentUserId);
    final hasVoted = userVote != null;
    return Card(margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.poll, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(poll.question, style: Theme.of(context).textTheme.titleMedium)),
      ]),
      const SizedBox(height: 4),
      Text('\${poll.totalVotes} vote\${poll.totalVotes == 1 ? "" : "s"}', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      ...poll.options.map((option) {
        final votes = poll.votesFor(option);
        final total = poll.totalVotes;
        final pct = total > 0 ? votes / total : 0.0;
        final isSelected = userVote == option;
        return GestureDetector(
          onTap: hasVoted ? null : () async {
            await FirebaseFirestore.instance.collection('polls').doc(poll.id).update({'votes.\$option': FieldValue.arrayUnion([currentUserId])});
          },
          child: Container(margin: const EdgeInsets.only(bottom: 8), child: Stack(children: [
            Container(height: 44, decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 1.5 : 1))),
            if (hasVoted) FractionallySizedBox(widthFactor: pct, child: Container(height: 44, decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.divider.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
            Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
              if (isSelected) const SizedBox(width: 6),
              Expanded(child: Text(option, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.textPrimary))),
              if (hasVoted) Text('\${(pct * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
            ]))),
          ])),
        );
      }),
      if (!hasVoted) Text('Tap an option to vote', style: Theme.of(context).textTheme.bodySmall),
    ])));
  }
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\features\polls\polls_screen.dart" -ForegroundColor Cyan

# ── suggestion_box_screen.dart ────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\features\suggestions\suggestion_box_screen.dart", @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../shared/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/phase2_models.dart';

final suggestionsProvider = StreamProvider<List<SuggestionModel>>((ref) {
  return FirebaseFirestore.instance.collection('suggestions').orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(SuggestionModel.fromFirestore).toList());
});

class SuggestionBoxScreen extends ConsumerStatefulWidget {
  const SuggestionBoxScreen({super.key});
  @override
  ConsumerState<SuggestionBoxScreen> createState() => _State();
}

class _State extends ConsumerState<SuggestionBoxScreen> {
  final _ctrl = TextEditingController();
  bool _anon = true, _sending = false;
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final user = ref.read(currentUserProvider).valueOrNull;
    final s = SuggestionModel(id: const Uuid().v4(), content: _ctrl.text.trim(), userId: _anon ? null : user?.uid, createdAt: DateTime.now());
    await FirebaseFirestore.instance.collection('suggestions').doc(s.id).set(s.toFirestore());
    _ctrl.clear();
    setState(() => _sending = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suggestion submitted! Thank you.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(suggestionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Suggestion Box')),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider.withOpacity(0.5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Row(children: [Icon(Icons.lightbulb_outline, color: AppColors.warning), SizedBox(width: 8), Expanded(child: Text('Share ideas with leadership', style: TextStyle(fontWeight: FontWeight.w600)))]),
              const SizedBox(height: 12),
              TextField(controller: _ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Type your suggestion here...', alignLabelWithHint: true)),
              const SizedBox(height: 8),
              Row(children: [Switch(value: _anon, onChanged: (v) => setState(() => _anon = v)), const Text('Submit anonymously')]),
              ElevatedButton(onPressed: _sending ? null : _submit, child: _sending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Suggestion')),
            ])),
        if (user?.isAdmin == true)
          Expanded(child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: \$e')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No suggestions yet.'))
                : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: list.length,
                    itemBuilder: (_, i) => Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(list[i].userId == null ? 'Anonymous' : 'Member', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
                        const Spacer(),
                        Text(DateFormat('d MMM y').format(list[i].createdAt), style: Theme.of(context).textTheme.bodySmall),
                        if (!list[i].isRead) Container(margin: const EdgeInsets.only(left: 6), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                      ]),
                      const SizedBox(height: 8),
                      Text(list[i].content, style: Theme.of(context).textTheme.bodyMedium),
                      if (!list[i].isRead) TextButton(onPressed: () => FirebaseFirestore.instance.collection('suggestions').doc(list[i].id).update({'isRead': true}), child: const Text('Mark as read')),
                    ]))))
          ))
        else
          Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Your suggestion goes directly to leadership.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            Text('All suggestions are confidential.', style: Theme.of(context).textTheme.bodySmall),
          ]))),
      ]),
    );
  }
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\features\suggestions\suggestion_box_screen.dart" -ForegroundColor Cyan

# ── badges_screen.dart ────────────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\features\badges\badges_screen.dart", @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../shared/utils/badge_utils.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final earned = BadgeUtils.getEarnedBadges(user.attendanceCount, user.streak);
    final nextBadge = BadgeUtils.getNextBadge(user.attendanceCount);
    final all = [...BadgeUtils.attendanceBadges, ...BadgeUtils.streakBadges];
    final earnedTypes = earned.map((b) => b.type).toSet();
    return Scaffold(
      appBar: AppBar(title: const Text('My Achievements')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: Column(children: [Text('\${user.attendanceCount}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)), Text('Sessions', style: TextStyle(color: Colors.white.withOpacity(0.7)))])),
            Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
            Expanded(child: Column(children: [Text('\${user.streak}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)), Text('Streak', style: TextStyle(color: Colors.white.withOpacity(0.7)))])),
            Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
            Expanded(child: Column(children: [Text('\${earned.length}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)), Text('Badges', style: TextStyle(color: Colors.white.withOpacity(0.7)))])),
          ])),
        const SizedBox(height: 20),
        if (nextBadge != null) ...[
          Text('Next Badge', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider.withOpacity(0.5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: nextBadge.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(nextBadge.icon, color: nextBadge.color, size: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(nextBadge.title, style: Theme.of(context).textTheme.titleMedium), Text(nextBadge.description, style: Theme.of(context).textTheme.bodySmall)])),
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: user.attendanceCount / nextBadge.requiredCount, backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation<Color>(nextBadge.color), borderRadius: BorderRadius.circular(4), minHeight: 8),
              const SizedBox(height: 6),
              Text('\${user.attendanceCount} / \${nextBadge.requiredCount} sessions', style: Theme.of(context).textTheme.bodySmall),
            ])),
          const SizedBox(height: 20),
        ],
        Text('All Badges', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1),
          itemCount: all.length,
          itemBuilder: (_, i) {
            final badge = all[i];
            final isEarned = earnedTypes.contains(badge.type);
            return Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isEarned ? Colors.white : AppColors.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isEarned ? badge.color.withOpacity(0.3) : AppColors.divider, width: isEarned ? 1.5 : 1)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isEarned ? badge.color.withOpacity(0.1) : AppColors.divider.withOpacity(0.3), shape: BoxShape.circle),
                    child: Icon(isEarned ? badge.icon : Icons.lock, color: isEarned ? badge.color : AppColors.textHint, size: 28)),
                const SizedBox(height: 8),
                Text(badge.title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isEarned ? AppColors.textPrimary : AppColors.textHint)),
                const SizedBox(height: 4),
                Text(badge.description, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: isEarned ? AppColors.textSecondary : AppColors.textHint)),
              ]),
            );
          }),
      ]),
    );
  }
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\features\badges\badges_screen.dart" -ForegroundColor Cyan

# ── leaderboard_screen.dart ───────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\features\leaderboard\leaderboard_screen.dart", @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/safe_avatar.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _State();
}

class _State extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'),
        bottom: TabBar(controller: _tabs, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Attendance', icon: Icon(Icons.check_circle, size: 16)), Tab(text: 'Streak', icon: Icon(Icons.local_fire_department, size: 16))])),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (members) {
          final byAtt = [...members]..sort((a, b) => b.attendanceCount.compareTo(a.attendanceCount));
          final byStr = [...members]..sort((a, b) => b.streak.compareTo(a.streak));
          return TabBarView(controller: _tabs, children: [
            _LeaderList(members: byAtt, myId: me?.uid ?? '', valueGetter: (m) => m.attendanceCount, valueLabel: 'sessions', color: AppColors.success),
            _LeaderList(members: byStr, myId: me?.uid ?? '', valueGetter: (m) => m.streak, valueLabel: 'streak', color: AppColors.warning),
          ]);
        }),
    );
  }
}

class _LeaderList extends StatelessWidget {
  final List<UserModel> members; final String myId;
  final int Function(UserModel) valueGetter; final String valueLabel; final Color color;
  const _LeaderList({required this.members, required this.myId, required this.valueGetter, required this.valueLabel, required this.color});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16), itemCount: members.length,
    itemBuilder: (_, i) {
      final m = members[i]; final val = valueGetter(m); final isMe = m.uid == myId; final rank = i + 1;
      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isMe ? AppColors.primary.withOpacity(0.06) : Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isMe ? AppColors.primary.withOpacity(0.3) : AppColors.divider.withOpacity(0.5), width: isMe ? 1.5 : 1)),
        child: Row(children: [
          SizedBox(width: 36, child: rank <= 3
              ? Text(['🥇','🥈','🥉'][rank-1], style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)
              : Text('#\$rank', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: isMe ? AppColors.primary : AppColors.textSecondary))),
          const SizedBox(width: 10),
          SafeAvatar(photoUrl: m.photoUrl, name: m.name, voicePart: m.voicePart, radius: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? '\${m.name} (You)' : m.name, style: TextStyle(fontWeight: FontWeight.w600, color: isMe ? AppColors.primary : AppColors.textPrimary)),
            Text(m.voicePart.toUpperCase(), style: TextStyle(fontSize: 11, color: voicePartColor(m.voicePart), fontWeight: FontWeight.w500)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('\$val \$valueLabel', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      );
    });
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\features\leaderboard\leaderboard_screen.dart" -ForegroundColor Cyan

# ── gallery_screen.dart ───────────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\features\gallery\gallery_screen.dart", @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/phase2_models.dart';

final galleryProvider = StreamProvider<List<GalleryPhoto>>((ref) {
  return FirebaseFirestore.instance.collection('gallery').orderBy('uploadedAt', descending: true).snapshots().map((s) => s.docs.map(GalleryPhoto.fromFirestore).toList());
});

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(galleryProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Gallery')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (photos) => photos.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.photo_library, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No photos yet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Share memories from rehearsals and performances!', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ]))
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                itemCount: photos.length,
                itemBuilder: (_, i) => _PhotoCard(photo: photos[i], currentUserId: user?.uid ?? ''),
              ),
      ),
      floatingActionButton: user != null ? FloatingActionButton.extended(
          onPressed: () => _showAdd(context, ref, user),
          icon: const Icon(Icons.add_photo_alternate), label: const Text('Add Photo'),
          backgroundColor: AppColors.primary) : null,
    );
  }

  void _showAdd(BuildContext ctx, WidgetRef ref, user) {
    final urlCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    showModalBottomSheet(context: ctx, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (c) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Add Photo', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://i.ibb.co/...', prefixIcon: Icon(Icons.link))),
            const SizedBox(height: 12),
            TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Caption (optional)')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () async {
              if (urlCtrl.text.trim().isEmpty) return;
              final p = GalleryPhoto(id: const Uuid().v4(), imageUrl: urlCtrl.text.trim(), caption: capCtrl.text.trim(), uploadedBy: user.uid, uploadedByName: user.name, uploadedAt: DateTime.now());
              await FirebaseFirestore.instance.collection('gallery').doc(p.id).set(p.toFirestore());
              if (c.mounted) Navigator.pop(c);
            }, child: const Text('Add to Gallery')),
          ])));
  }
}

class _PhotoCard extends StatelessWidget {
  final GalleryPhoto photo; final String currentUserId;
  const _PhotoCard({required this.photo, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final hasLiked = photo.likes.contains(currentUserId);
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero,
          child: Stack(children: [
            Center(child: Image.network(photo.imageUrl, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64))),
            Positioned(top: 40, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
            if (photo.caption.isNotEmpty) Positioned(bottom: 40, left: 16, right: 16, child: Text(photo.caption, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center)),
          ]))),
      child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(photo.imageUrl, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: AppColors.textHint, size: 48))))),
          Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (photo.caption.isNotEmpty) Text(photo.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Row(children: [
              GestureDetector(
                onTap: () async {
                  final r = FirebaseFirestore.instance.collection('gallery').doc(photo.id);
                  if (hasLiked) { await r.update({'likes': FieldValue.arrayRemove([currentUserId])}); }
                  else { await r.update({'likes': FieldValue.arrayUnion([currentUserId])}); }
                },
                child: Row(children: [
                  Icon(hasLiked ? Icons.favorite : Icons.favorite_border, size: 16, color: hasLiked ? Colors.red : AppColors.textHint),
                  const SizedBox(width: 3),
                  Text('\${photo.likes.length}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ]),
              ),
              const Spacer(),
              Text(photo.uploadedByName.split(' ').first, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ]),
          ])),
        ]),
      ),
    );
  }
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\features\gallery\gallery_screen.dart" -ForegroundColor Cyan

# ── Update router ─────────────────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\router\router.dart", @"
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
import '../features/testimonies/testimonies_screen.dart';
import '../features/shoutouts/shoutouts_screen.dart';
import '../features/polls/polls_screen.dart';
import '../features/suggestions/suggestion_box_screen.dart';
import '../features/badges/badges_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(initialLocation: '/splash', routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
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
      const Text('Group chat and messaging coming soon!', textAlign: TextAlign.center),
    ])));
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  updated: lib\router\router.dart" -ForegroundColor Cyan

# ── Update home screen with grid of all features ──────────────────────────────
[System.IO.File]::WriteAllText("lib\features\home\home_screen.dart", @"
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
      appBar: AppBar(title: const Text('Asempa Choir'),
          actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})]),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
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
            songsAsync.when(loading: () => const SizedBox(), error: (_, __) => const SizedBox(),
              data: (songs) => songs.isEmpty ? const SizedBox() : _SectionCard(icon: Icons.music_note, title: 'Recent Songs', onViewAll: () => context.push('/music'),
                children: songs.take(3).map((s) => ListTile(contentPadding: EdgeInsets.zero, title: Text(s.title, style: Theme.of(context).textTheme.titleMedium), trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 16),

            // Rehearsals
            _SectionCard(icon: Icons.calendar_today, title: 'Upcoming Rehearsals', onViewAll: () => context.push('/schedule'),
              children: rehearsalsAsync.when(
                loading: () => [const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (r) => r.isEmpty
                    ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No upcoming rehearsals', style: Theme.of(context).textTheme.bodyMedium))]
                    : r.take(3).map((reh) => ListTile(contentPadding: EdgeInsets.zero, title: Text(reh.title ?? 'Rehearsal'), subtitle: Text(DateFormat('EEE, MMM d | h:mm a').format(reh.date)), trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 16),

            // Announcements
            _SectionCard(icon: Icons.campaign, title: 'Recent Announcements',
              children: announcementsAsync.when(
                loading: () => [const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (items) => items.isEmpty
                    ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No announcements', style: Theme.of(context).textTheme.bodyMedium))]
                    : items.take(3).map((a) => ListTile(contentPadding: EdgeInsets.zero,
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.campaign, size: 20, color: AppColors.textSecondary)),
                        title: Text(a.title), subtitle: Text(DateFormat('d MMM y').format(a.createdAt)), trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 20),

            // Features Grid
            Text('Features', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9,
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
  final IconData icon; final Color iconColor; final String value, label; final VoidCallback? onTap;
  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider.withOpacity(0.5))),
    child: Column(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: iconColor)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  ));
}

class _SectionCard extends StatelessWidget {
  final IconData icon; final String title; final List<Widget> children; final VoidCallback? onViewAll;
  const _SectionCard({required this.icon, required this.title, required this.children, this.onViewAll});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider.withOpacity(0.5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: AppColors.textSecondary)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('See all')),
      ]),
      ...children,
    ]),
  );
}

class _GridFeature extends StatelessWidget {
  final IconData icon; final String label; final Color color, iconColor; final VoidCallback onTap;
  const _GridFeature({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider.withOpacity(0.5))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 22)),
      const SizedBox(height: 6),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    ]),
  ));
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  updated: lib\features\home\home_screen.dart" -ForegroundColor Cyan

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " Phase 2 & 3 all done!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "New screens:" -ForegroundColor Cyan
Write-Host "  Testimonies, Shoutouts, Polls, Suggestion Box" -ForegroundColor White
Write-Host "  Badges, Leaderboard, Gallery" -ForegroundColor White
Write-Host ""
Write-Host "Press 'R' in Flutter terminal for full restart" -ForegroundColor Yellow
