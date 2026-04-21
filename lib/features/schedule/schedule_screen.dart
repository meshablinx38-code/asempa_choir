import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/models.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rehearsalsAsync = ref.watch(upcomingRehearsalsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: rehearsalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rehearsals) => rehearsals.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.event_available, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No upcoming rehearsals', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Check back later or ask your choir leader.',
                    style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rehearsals.length,
                itemBuilder: (_, i) => _RehearsalCard(
                    rehearsal: rehearsals[i],
                    isAdmin: user?.isAdmin ?? false,
                    ref: ref),
              ),
      ),
      floatingActionButton: user?.isAdmin == true
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context, ref, user!.uid),
              icon: const Icon(Icons.add),
              label: const Text('Add Rehearsal'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String uid) {
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);

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
            Container(width: 40, height: 4, alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Add Rehearsal', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title',
                    prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 12),
            TextField(controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location (optional)',
                    prefixIcon: Icon(Icons.location_on_outlined))),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes))),
            const SizedBox(height: 12),
            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: Text(DateFormat('EEE, MMM d y').format(selectedDate)),
              subtitle: const Text('Tap to change date'),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setModalState(() => selectedDate = d);
              },
            ),
            // Time picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: Text(selectedTime.format(ctx)),
              subtitle: const Text('Tap to change time'),
              onTap: () async {
                final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                if (t != null) setModalState(() => selectedTime = t);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final dt = DateTime(selectedDate.year, selectedDate.month,
                    selectedDate.day, selectedTime.hour, selectedTime.minute);
                final r = RehearsalModel(
                  id: const Uuid().v4(),
                  rehearsalId: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: dt,
                  title: titleCtrl.text.trim(),
                  location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                await ref.read(firestoreServiceProvider).addRehearsal(r);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Save Rehearsal'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RehearsalCard extends StatelessWidget {
  final RehearsalModel rehearsal;
  final bool isAdmin;
  final WidgetRef ref;
  const _RehearsalCard({required this.rehearsal, required this.isAdmin, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(rehearsal.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isTomorrow = DateFormat('yyyy-MM-dd').format(rehearsal.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Date badge
          Container(
            width: 52, padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(DateFormat('MMM').format(rehearsal.date).toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white70 : AppColors.textHint)),
              Text(DateFormat('d').format(rehearsal.date),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: isToday ? Colors.white : AppColors.textPrimary)),
              Text(DateFormat('EEE').format(rehearsal.date),
                  style: TextStyle(fontSize: 11,
                      color: isToday ? Colors.white70 : AppColors.textHint)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(rehearsal.title ?? 'Rehearsal',
                  style: Theme.of(context).textTheme.titleMedium)),
              if (isToday)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Today', style: TextStyle(color: AppColors.success,
                        fontSize: 11, fontWeight: FontWeight.w600))),
              if (isTomorrow)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Tomorrow', style: TextStyle(color: AppColors.warning,
                        fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(DateFormat('h:mm a').format(rehearsal.date),
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
            if (rehearsal.location != null && rehearsal.location!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(rehearsal.location!, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ],
            if (rehearsal.notes != null && rehearsal.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(rehearsal.notes!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 6),
            Text('${rehearsal.attendees.length} attendee${rehearsal.attendees.length == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
          ])),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Rehearsal'),
                    content: const Text('Are you sure you want to delete this rehearsal?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(firestoreServiceProvider).deleteRehearsal(rehearsal.id);
                }
              },
            ),
        ]),
      ),
    );
  }
}