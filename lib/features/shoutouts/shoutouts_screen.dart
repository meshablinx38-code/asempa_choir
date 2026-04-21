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
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.celebration, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No shoutouts yet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Appreciate a fellow choir member!', style: Theme.of(context).textTheme.bodyMedium),
              ]))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => _ShoutoutCard(shoutout: list[i], currentUserId: user?.uid ?? ''))),
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
                items: members.where((m) => m.uid != user.uid).map((m) => DropdownMenuItem(value: m, child: Text(m.name + ' (' + m.voicePart + ')'))).toList(),
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
          Text(shoutout.likes.length.toString(), style: TextStyle(color: hasLiked ? Colors.red : AppColors.textHint, fontSize: 13)),
        ]),
      ),
    ])));
  }
}
