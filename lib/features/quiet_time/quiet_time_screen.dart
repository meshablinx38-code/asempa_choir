import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/models.dart';

class QuietTimeScreen extends ConsumerWidget {
  const QuietTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(quietTimePostsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiet Time')),
      body: Column(children: [
        // Post button
        if (user != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showPostDialog(context, ref, user),
              icon: const Icon(Icons.add),
              label: const Text('Share Today\'s Quiet Time'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            ),
          ),

        Expanded(child: postsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (posts) => posts.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book, size: 64, color: AppColors.textHint),
                    SizedBox(height: 16),
                    Text('No quiet time posts yet.\nBe the first to share!',
                        textAlign: TextAlign.center),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: posts.length,
                  itemBuilder: (_, i) => _QtCard(post: posts[i])),
        )),
      ]),
    );
  }

  void _showPostDialog(BuildContext context, WidgetRef ref, user) {
    final verseCtrl = TextEditingController();
    final reflectionCtrl = TextEditingController();
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Share Quiet Time', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: verseCtrl,
                decoration: const InputDecoration(labelText: 'Bible Verse (e.g. John 3:16)',
                    prefixIcon: Icon(Icons.bookmark_outline))),
            const SizedBox(height: 12),
            TextField(controller: reflectionCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Your Reflection',
                    prefixIcon: Icon(Icons.edit_note), alignLabelWithHint: true)),
            const SizedBox(height: 8),
            Row(children: [
              Switch(value: isAnonymous,
                  onChanged: (v) => setModalState(() => isAnonymous = v)),
              const Text('Post anonymously'),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (verseCtrl.text.isEmpty || reflectionCtrl.text.isEmpty) return;
                final post = QuietTimePost(
                  id: const Uuid().v4(),
                  userId: user.uid,
                  fullName: isAnonymous ? 'Anonymous' : user.name,
                  verse: verseCtrl.text.trim(),
                  reflection: reflectionCtrl.text.trim(),
                  voicePart: user.voicePart,
                  isAnonymous: isAnonymous,
                  timestamp: DateTime.now(),
                );
                await ref.read(firestoreServiceProvider).postQuietTime(post);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Post'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QtCard extends StatelessWidget {
  final QuietTimePost post;
  const _QtCard({required this.post});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: voicePartColor(post.voicePart ?? '').withOpacity(0.2),
            child: Text(post.fullName[0].toUpperCase(),
                style: TextStyle(color: voicePartColor(post.voicePart ?? ''),
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.isAnonymous ? 'Anonymous' : post.fullName,
                style: Theme.of(context).textTheme.titleMedium),
            if (post.voicePart != null && post.voicePart!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: voicePartColor(post.voicePart!).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(post.voicePart!.toUpperCase(),
                    style: TextStyle(color: voicePartColor(post.voicePart!),
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ),
          ])),
          Text(DateFormat('MMM d').format(post.timestamp),
              style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(8),
          ),
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