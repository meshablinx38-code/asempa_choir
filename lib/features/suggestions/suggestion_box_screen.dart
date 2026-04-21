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
            error: (e, _) => Center(child: Text(e.toString())),
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
