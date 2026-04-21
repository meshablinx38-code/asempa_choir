function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $path" -ForegroundColor Cyan
}

# Create all folders
$folders = @(
    "lib\models",
    "lib\shared\utils",
    "lib\features\testimonies",
    "lib\features\shoutouts",
    "lib\features\polls",
    "lib\features\suggestions",
    "lib\features\badges",
    "lib\features\leaderboard",
    "lib\features\gallery"
)
foreach ($f in $folders) { New-Item -ItemType Directory -Force -Path $f | Out-Null }
Write-Host "Folders created" -ForegroundColor Green

# ── phase2_models.dart ────────────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\models\phase2_models.dart", @"
import 'package:cloud_firestore/cloud_firestore.dart';

class TestimonyModel {
  final String id, userId, fullName, voicePart, title, content;
  final bool isAnonymous, isApproved;
  final DateTime createdAt;
  final List<String> likes;
  const TestimonyModel({required this.id, required this.userId, required this.fullName, required this.voicePart, required this.title, required this.content, this.isAnonymous = false, this.isApproved = false, required this.createdAt, this.likes = const []});
  factory TestimonyModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TestimonyModel(id: doc.id, userId: d['userId'] ?? '', fullName: d['fullName'] ?? 'Anonymous', voicePart: d['voicePart'] ?? '', title: d['title'] ?? '', content: d['content'] ?? '', isAnonymous: d['isAnonymous'] ?? false, isApproved: d['isApproved'] ?? false, createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), likes: List<String>.from(d['likes'] ?? []));
  }
  Map<String, dynamic> toFirestore() => {'userId': userId, 'fullName': fullName, 'voicePart': voicePart, 'title': title, 'content': content, 'isAnonymous': isAnonymous, 'isApproved': isApproved, 'createdAt': Timestamp.fromDate(createdAt), 'likes': likes};
}

class ShoutoutModel {
  final String id, fromUserId, fromName, toUserId, toName, message;
  final String? fromVoicePart, toVoicePart;
  final DateTime createdAt;
  final List<String> likes;
  const ShoutoutModel({required this.id, required this.fromUserId, required this.fromName, required this.toUserId, required this.toName, required this.message, this.fromVoicePart, this.toVoicePart, required this.createdAt, this.likes = const []});
  factory ShoutoutModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShoutoutModel(id: doc.id, fromUserId: d['fromUserId'] ?? '', fromName: d['fromName'] ?? '', toUserId: d['toUserId'] ?? '', toName: d['toName'] ?? '', message: d['message'] ?? '', fromVoicePart: d['fromVoicePart'], toVoicePart: d['toVoicePart'], createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), likes: List<String>.from(d['likes'] ?? []));
  }
  Map<String, dynamic> toFirestore() => {'fromUserId': fromUserId, 'fromName': fromName, 'toUserId': toUserId, 'toName': toName, 'message': message, 'fromVoicePart': fromVoicePart, 'toVoicePart': toVoicePart, 'createdAt': Timestamp.fromDate(createdAt), 'likes': likes};
}

class PollModel {
  final String id, question, createdBy;
  final List<String> options;
  final Map<String, List<String>> votes;
  final DateTime createdAt;
  final bool isActive;
  const PollModel({required this.id, required this.question, required this.createdBy, required this.options, this.votes = const {}, required this.createdAt, this.isActive = true});
  int votesFor(String option) => (votes[option] ?? []).length;
  int get totalVotes => votes.values.fold(0, (sum, v) => sum + v.length);
  String? userVote(String uid) { for (final e in votes.entries) { if (e.value.contains(uid)) return e.key; } return null; }
  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final vr = d['votes'] as Map<String, dynamic>? ?? {};
    return PollModel(id: doc.id, question: d['question'] ?? '', createdBy: d['createdBy'] ?? '', options: List<String>.from(d['options'] ?? []), votes: vr.map((k, v) => MapEntry(k, List<String>.from(v))), createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), isActive: d['isActive'] ?? true);
  }
  Map<String, dynamic> toFirestore() => {'question': question, 'createdBy': createdBy, 'options': options, 'votes': votes, 'createdAt': Timestamp.fromDate(createdAt), 'isActive': isActive};
}

class SuggestionModel {
  final String id, content;
  final String? userId;
  final DateTime createdAt;
  final bool isRead;
  const SuggestionModel({required this.id, required this.content, this.userId, required this.createdAt, this.isRead = false});
  factory SuggestionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SuggestionModel(id: doc.id, content: d['content'] ?? '', userId: d['userId'], isRead: d['isRead'] ?? false, createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now());
  }
  Map<String, dynamic> toFirestore() => {'content': content, 'userId': userId, 'isRead': isRead, 'createdAt': Timestamp.fromDate(createdAt)};
}

class GalleryPhoto {
  final String id, imageUrl, caption, uploadedBy, uploadedByName;
  final DateTime uploadedAt;
  final List<String> likes;
  const GalleryPhoto({required this.id, required this.imageUrl, required this.caption, required this.uploadedBy, required this.uploadedByName, required this.uploadedAt, this.likes = const []});
  factory GalleryPhoto.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GalleryPhoto(id: doc.id, imageUrl: d['imageUrl'] ?? '', caption: d['caption'] ?? '', uploadedBy: d['uploadedBy'] ?? '', uploadedByName: d['uploadedByName'] ?? '', uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(), likes: List<String>.from(d['likes'] ?? []));
  }
  Map<String, dynamic> toFirestore() => {'imageUrl': imageUrl, 'caption': caption, 'uploadedBy': uploadedBy, 'uploadedByName': uploadedByName, 'uploadedAt': Timestamp.fromDate(uploadedAt), 'likes': likes};
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\models\phase2_models.dart" -ForegroundColor Cyan

# ── badge_utils.dart ──────────────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\shared\utils\badge_utils.dart", @"
import 'package:flutter/material.dart';

class BadgeInfo {
  final String type, title, description;
  final IconData icon;
  final Color color;
  final int requiredCount;
  const BadgeInfo({required this.type, required this.title, required this.description, required this.icon, required this.color, required this.requiredCount});
}

class BadgeUtils {
  static const List<BadgeInfo> attendanceBadges = [
    BadgeInfo(type: 'first_checkin', title: 'First Step', description: 'Attended your first rehearsal', icon: Icons.directions_walk, color: Colors.green, requiredCount: 1),
    BadgeInfo(type: 'five_sessions', title: 'Getting Started', description: 'Attended 5 rehearsals', icon: Icons.star, color: Colors.blue, requiredCount: 5),
    BadgeInfo(type: 'ten_sessions', title: 'Committed', description: 'Attended 10 rehearsals', icon: Icons.star_half, color: Colors.orange, requiredCount: 10),
    BadgeInfo(type: 'twenty_sessions', title: 'Dedicated', description: 'Attended 20 rehearsals', icon: Icons.workspace_premium, color: Colors.purple, requiredCount: 20),
    BadgeInfo(type: 'fifty_sessions', title: 'Legend', description: 'Attended 50 rehearsals', icon: Icons.emoji_events, color: Colors.amber, requiredCount: 50),
  ];
  static const List<BadgeInfo> streakBadges = [
    BadgeInfo(type: 'streak_3', title: 'On Fire', description: '3 session streak', icon: Icons.local_fire_department, color: Colors.deepOrange, requiredCount: 3),
    BadgeInfo(type: 'streak_5', title: 'Hot Streak', description: '5 session streak', icon: Icons.bolt, color: Colors.red, requiredCount: 5),
    BadgeInfo(type: 'streak_10', title: 'Unstoppable', description: '10 session streak', icon: Icons.flash_on, color: Colors.pink, requiredCount: 10),
  ];
  static List<BadgeInfo> getEarnedBadges(int attendance, int streak) {
    final earned = <BadgeInfo>[];
    for (final b in attendanceBadges) { if (attendance >= b.requiredCount) earned.add(b); }
    for (final b in streakBadges) { if (streak >= b.requiredCount) earned.add(b); }
    return earned;
  }
  static BadgeInfo? getNextBadge(int attendance) {
    for (final b in attendanceBadges) { if (attendance < b.requiredCount) return b; }
    return null;
  }
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\shared\utils\badge_utils.dart" -ForegroundColor Cyan

# ── testimonies_screen.dart ───────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\features\testimonies\testimonies_screen.dart", @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/safe_avatar.dart';
import '../../providers/providers.dart';
import '../../models/phase2_models.dart';

final testimoniesProvider = StreamProvider<List<TestimonyModel>>((ref) {
  return FirebaseFirestore.instance.collection('testimonies').where('isApproved', isEqualTo: true).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(TestimonyModel.fromFirestore).toList());
});

class TestimoniesScreen extends ConsumerWidget {
  const TestimoniesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(testimoniesProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Testimonies')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.volunteer_activism, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No testimonies yet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Be the first to share what God has done!', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _TestimonyCard(testimony: list[i], currentUserId: user?.uid ?? '')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostDialog(context, ref, user),
        icon: const Icon(Icons.add), label: const Text('Share Testimony'),
        backgroundColor: AppColors.primary),
    );
  }

  void _showPostDialog(BuildContext ctx, WidgetRef ref, user) {
    if (user == null) return;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool anon = false;
    showModalBottomSheet(context: ctx, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (c) => StatefulBuilder(builder: (c, set) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Share Your Testimony', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: contentCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Your testimony', alignLabelWithHint: true)),
            const SizedBox(height: 8),
            Row(children: [Switch(value: anon, onChanged: (v) => set(() => anon = v)), const Text('Post anonymously')]),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: const Text('Your testimony will be reviewed before appearing.', style: TextStyle(fontSize: 12, color: AppColors.info))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () async {
              if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
              final t = TestimonyModel(id: const Uuid().v4(), userId: user.uid, fullName: anon ? 'Anonymous' : user.name, voicePart: user.voicePart, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), isAnonymous: anon, isApproved: false, createdAt: DateTime.now());
              await FirebaseFirestore.instance.collection('testimonies').doc(t.id).set(t.toFirestore());
              if (c.mounted) { Navigator.pop(c); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Testimony submitted for review!'))); }
            }, child: const Text('Submit for Review')),
          ]),
        )));
  }
}

class _TestimonyCard extends StatelessWidget {
  final TestimonyModel testimony; final String currentUserId;
  const _TestimonyCard({required this.testimony, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    final hasLiked = testimony.likes.contains(currentUserId);
    return Card(margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SafeAvatar(photoUrl: null, name: testimony.fullName, voicePart: testimony.voicePart, radius: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(testimony.isAnonymous ? 'Anonymous' : testimony.fullName, style: Theme.of(context).textTheme.titleMedium),
          Text(DateFormat('d MMM y').format(testimony.createdAt), style: Theme.of(context).textTheme.bodySmall),
        ])),
        const Icon(Icons.volunteer_activism, color: Colors.pink),
      ]),
      const SizedBox(height: 12),
      Text(testimony.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(testimony.content, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final r = FirebaseFirestore.instance.collection('testimonies').doc(testimony.id);
          if (hasLiked) { await r.update({'likes': FieldValue.arrayRemove([currentUserId])}); }
          else { await r.update({'likes': FieldValue.arrayUnion([currentUserId])}); }
        },
        child: Row(children: [
          Icon(hasLiked ? Icons.favorite : Icons.favorite_border, color: hasLiked ? Colors.red : AppColors.textHint, size: 20),
          const SizedBox(width: 4),
          Text('\${testimony.likes.length}', style: TextStyle(color: hasLiked ? Colors.red : AppColors.textHint)),
        ]),
      ),
    ])));
  }
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\features\testimonies\testimonies_screen.dart" -ForegroundColor Cyan

# ── shoutouts_screen.dart ─────────────────────────────────────────────────────
[System.IO.File]::WriteAllText("lib\features\shoutouts\shoutouts_screen.dart", @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/safe_avatar.dart';
import '../../providers/providers.dart';
import '../../models/phase2_models.dart';
import '../../models/user_model.dart';

final shoutoutsProvider = StreamProvider<List<ShoutoutModel>>((ref) {
  return FirebaseFirestore.instance.collection('shoutouts').orderBy('createdAt', descending: true).limit(30).snapshots().map((s) => s.docs.map(ShoutoutModel.fromFirestore).toList());
});

class ShoutoutsScreen extends ConsumerWidget {
  const ShoutoutsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shoutoutsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Shoutouts Wall')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.celebration, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No shoutouts yet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Appreciate a fellow choir member!', style: Theme.of(context).textTheme.bodyMedium),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _ShoutoutCard(shoutout: list[i], currentUserId: user?.uid ?? '')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, ref, user),
        icon: const Icon(Icons.favorite), label: const Text('Give Shoutout'),
        backgroundColor: Colors.pink),
    );
  }

  void _showDialog(BuildContext ctx, WidgetRef ref, user) {
    if (user == null) return;
    UserModel? selected;
    final msgCtrl = TextEditingController();
    showModalBottomSheet(context: ctx, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (c) => StatefulBuilder(builder: (c, set) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Give a Shoutout', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ref.watch(allMembersProvider).when(
              loading: () => const CircularProgressIndicator(), error: (_, __) => const SizedBox(),
              data: (members) => DropdownButtonFormField<UserModel>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Who are you appreciating?'),
                items: members.where((m) => m.uid != user.uid).map((m) => DropdownMenuItem(value: m, child: Text('\${m.name} (\${m.voicePart})'))).toList(),
                onChanged: (v) => set(() => selected = v),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Your message', alignLabelWithHint: true)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (selected == null || msgCtrl.text.isEmpty) return;
                final s = ShoutoutModel(id: const Uuid().v4(), fromUserId: user.uid, fromName: user.name, toUserId: selected!.uid, toName: selected!.name, message: msgCtrl.text.trim(), fromVoicePart: user.voicePart, toVoicePart: selected!.voicePart, createdAt: DateTime.now());
                await FirebaseFirestore.instance.collection('shoutouts').doc(s.id).set(s.toFirestore());
                if (c.mounted) Navigator.pop(c);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: const Text('Send Shoutout'),
            ),
          ]),
        )));
  }
}

class _ShoutoutCard extends StatelessWidget {
  final ShoutoutModel shoutout; final String currentUserId;
  const _ShoutoutCard({required this.shoutout, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    final hasLiked = shoutout.likes.contains(currentUserId);
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SafeAvatar(photoUrl: null, name: shoutout.fromName, voicePart: shoutout.fromVoicePart ?? '', radius: 18),
        const SizedBox(width: 8),
        Text(shoutout.fromName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: Colors.pink)),
        SafeAvatar(photoUrl: null, name: shoutout.toName, voicePart: shoutout.toVoicePart ?? '', radius: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(shoutout.toName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Text(DateFormat('d MMM').format(shoutout.createdAt), style: Theme.of(context).textTheme.bodySmall),
      ]),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.pink.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.pink.withOpacity(0.2))),
          child: Text(shoutout.message, style: Theme.of(context).textTheme.bodyMedium)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () async {
          final r = FirebaseFirestore.instance.collection('shoutouts').doc(shoutout.id);
          if (hasLiked) { await r.update({'likes': FieldValue.arrayRemove([currentUserId])}); }
          else { await r.update({'likes': FieldValue.arrayUnion([currentUserId])}); }
        },
        child: Row(children: [
          Icon(hasLiked ? Icons.favorite : Icons.favorite_border, color: hasLiked ? Colors.red : AppColors.textHint, size: 18),
          const SizedBox(width: 4),
          Text('\${shoutout.likes.length}', style: TextStyle(color: hasLiked ? Colors.red : AppColors.textHint, fontSize: 13)),
        ]),
      ),
    ])));
  }
}
"@, [System.Text.Encoding]::UTF8)
Write-Host "  created: lib\features\shoutouts\shoutouts_screen.dart" -ForegroundColor Cyan

Write-Host ""
Write-Host "Part 1 done! Now run part 2 script." -ForegroundColor Green
