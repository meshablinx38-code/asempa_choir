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