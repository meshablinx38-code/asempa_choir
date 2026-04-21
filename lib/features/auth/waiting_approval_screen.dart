import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class WaitingApprovalScreen extends ConsumerWidget {
  const WaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 100, height: 100,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.music_note, size: 52, color: Colors.white)),
          const SizedBox(height: 32),
          const Text('Account Pending Approval',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          if (user != null) ...
            [Text('Welcome, ' + user.name + '!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 8)],
          const Text(
            'Your registration is complete! The choir leader will review and approve your account shortly.\n\nYou will be able to access the app once approved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 32),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withOpacity(0.5))),
            child: const Column(children: [
              Row(children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Registration submitted', style: TextStyle(fontWeight: FontWeight.w500))),
              ]),
              SizedBox(height: 12),
              Row(children: [
                Icon(Icons.hourglass_empty, color: AppColors.warning, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Waiting for admin approval', style: TextStyle(fontWeight: FontWeight.w500))),
              ]),
              SizedBox(height: 12),
              Row(children: [
                Icon(Icons.lock_open, color: AppColors.textHint, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Access granted after approval', style: TextStyle(color: AppColors.textHint))),
              ]),
            ])),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48))),
        ]))),
    );
  }
}
