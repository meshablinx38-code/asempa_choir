# Complete remaining screens + build prep

function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $path" -ForegroundColor Cyan
}

# ══════════════════════════════════════════════════════════════════════════════
# Check-in Screen (QR Scanner)
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\checkin\checkin_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});
  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _processing = false;
  bool? _success;
  String? _message;

  // Since mobile_scanner may not work on web, we use a manual code entry fallback
  final _codeCtrl = TextEditingController();

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _checkIn(String code) async {
    if (code.trim().isEmpty) return;
    setState(() { _processing = true; _success = null; _message = null; });
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      final success = await ref.read(firestoreServiceProvider).checkIn(
        uid: user.uid, qrCode: code.trim(), fullName: user.name);
      setState(() {
        _success = success;
        _message = success
            ? 'Check-in successful! Welcome, ${user.firstName}!'
            : 'Invalid or expired session code. Please try again.';
        _processing = false;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _message = 'Check-in failed. Please try again.';
        _processing = false;
      });
    }
  }

  void _reset() {
    setState(() { _success = null; _message = null; _codeCtrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Check In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Status card
          if (_success != null)
            _ResultCard(success: _success!, message: _message ?? '', onReset: _reset)
          else ...[
            // Info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white, size: 56),
                const SizedBox(height: 12),
                const Text('Attendance Check-In',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Enter the session code shown by your admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 32),

            // Manual code entry
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider.withOpacity(0.5))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Enter Session Code', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Ask your choir leader for the session code',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Session Code',
                    prefixIcon: Icon(Icons.key_outlined),
                    hintText: 'Paste or type the code here',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _processing ? null : () => _checkIn(_codeCtrl.text),
                  icon: _processing
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_processing ? 'Checking in...' : 'Check In'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Member info
            if (user != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider.withOpacity(0.5))),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: voicePartColor(user.voicePart).withOpacity(0.2),
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(color: voicePartColor(user.voicePart), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Checking in as', style: Theme.of(context).textTheme.bodySmall),
                    Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(user.voicePart.toUpperCase(),
                        style: TextStyle(color: voicePartColor(user.voicePart),
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            const SizedBox(height: 16),
          ],

          // View history button
          Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: const Text('View My Attendance History'),
              subtitle: const Text('See all your past check-ins'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/attendance'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool success;
  final String message;
  final VoidCallback onReset;
  const _ResultCard({required this.success, required this.message, required this.onReset});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: success ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: success ? AppColors.success : AppColors.error, width: 1.5),
    ),
    child: Column(children: [
      Icon(success ? Icons.check_circle : Icons.cancel,
          size: 72, color: success ? AppColors.success : AppColors.error),
      const SizedBox(height: 16),
      Text(success ? 'Success!' : 'Failed',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
              color: success ? AppColors.success : AppColors.error)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: onReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: success ? AppColors.success : AppColors.error,
          minimumSize: const Size(double.infinity, 48)),
        child: const Text('Done'),
      ),
    ]),
  );
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Schedule Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\schedule\schedule_screen.dart" @'
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
'@

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " Check-in + Schedule screens done!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press 'R' in Flutter terminal for full restart" -ForegroundColor Cyan
Write-Host ""
Write-Host "To build APK run:" -ForegroundColor Yellow
Write-Host "  flutter build apk --release" -ForegroundColor White
Write-Host ""
Write-Host "APK will be at:" -ForegroundColor Yellow
Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
