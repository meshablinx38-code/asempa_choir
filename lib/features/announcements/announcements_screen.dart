import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/models.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No announcements yet.'),
                ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) => _AnnouncementCard(
                    item: items[i], isAdmin: user?.isAdmin ?? false, ref: ref),
              ),
      ),
      floatingActionButton: user?.isAdmin == true
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context, ref, user!),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, user) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('New Announcement', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: msgCtrl, maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Message', alignLabelWithHint: true)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || msgCtrl.text.isEmpty) return;
              final a = AnnouncementModel(
                id: const Uuid().v4(),
                title: titleCtrl.text.trim(),
                message: msgCtrl.text.trim(),
                createdBy: user.uid,
                createdAt: DateTime.now(),
              );
              await ref.read(firestoreServiceProvider).addAnnouncement(a);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Post Announcement'),
          ),
        ]),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel item;
  final bool isAdmin;
  final WidgetRef ref;
  const _AnnouncementCard({required this.item, required this.isAdmin, required this.ref});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            Text(DateFormat('d MMM y â€¢ h:mm a').format(item.createdAt),
                style: Theme.of(context).textTheme.bodySmall),
          ])),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => ref.read(firestoreServiceProvider)
                  .deleteAnnouncement(item.id),
            ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(item.message, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    ),
  );
}