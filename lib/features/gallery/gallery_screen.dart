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
        error: (e, _) => Center(child: Text(e.toString())),
        data: (photos) => photos.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.photo_library, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No photos yet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Share memories from rehearsals!', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ]))
            : GridView.builder(padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                itemCount: photos.length,
                itemBuilder: (_, i) => _PhotoCard(photo: photos[i], currentUserId: user?.uid ?? ''))),
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
                  Text(photo.likes.length.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
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
