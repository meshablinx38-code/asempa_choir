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
        error: (e, _) => Center(child: Text(e.toString())),
        data: (polls) => polls.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.poll, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No active polls', style: Theme.of(context).textTheme.headlineSmall),
              ]))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: polls.length,
                itemBuilder: (_, i) => _PollCard(poll: polls[i], currentUserId: user?.uid ?? ''))),
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
            ...List.generate(4, (i) => Padding(padding: const EdgeInsets.only(bottom: 8),
                child: TextField(controller: opts[i], decoration: InputDecoration(labelText: 'Option ' + (i+1).toString() + (i >= 2 ? ' (optional)' : ''))))),
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
      Row(children: [const Icon(Icons.poll, color: AppColors.primary, size: 20), const SizedBox(width: 8), Expanded(child: Text(poll.question, style: Theme.of(context).textTheme.titleMedium))]),
      const SizedBox(height: 4),
      Text(poll.totalVotes.toString() + ' vote' + (poll.totalVotes == 1 ? '' : 's'), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      ...poll.options.map((option) {
        final votes = poll.votesFor(option);
        final total = poll.totalVotes;
        final pct = total > 0 ? votes / total : 0.0;
        final isSelected = userVote == option;
        return GestureDetector(
          onTap: hasVoted ? null : () async {
            final update = <String, dynamic>{};
            update['votes.' + option] = FieldValue.arrayUnion([currentUserId]);
            await FirebaseFirestore.instance.collection('polls').doc(poll.id).update(update);
          },
          child: Container(margin: const EdgeInsets.only(bottom: 8), child: Stack(children: [
            Container(height: 44, decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 1.5 : 1))),
            if (hasVoted) FractionallySizedBox(widthFactor: pct, child: Container(height: 44, decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.divider.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
            Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
              if (isSelected) const SizedBox(width: 6),
              Expanded(child: Text(option, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.textPrimary))),
              if (hasVoted) Text((pct * 100).round().toString() + '%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
            ]))),
          ])));
      }),
      if (!hasVoted) Text('Tap an option to vote', style: Theme.of(context).textTheme.bodySmall),
    ])));
  }
}
