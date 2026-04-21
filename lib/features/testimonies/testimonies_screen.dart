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
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.volunteer_activism, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No testimonies yet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Be the first to share what God has done!', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ]))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => _TestimonyCard(testimony: list[i], currentUserId: user?.uid ?? ''))),
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
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Text('Your testimony will be reviewed before appearing.', style: TextStyle(fontSize: 12, color: AppColors.info))),
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
          Text(testimony.likes.length.toString(), style: TextStyle(color: hasLiked ? Colors.red : AppColors.textHint)),
        ]),
      ),
    ])));
  }
}
