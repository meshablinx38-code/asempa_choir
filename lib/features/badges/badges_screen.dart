import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../shared/utils/badge_utils.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final earned = BadgeUtils.getEarnedBadges(user.attendanceCount, user.streak);
    final nextBadge = BadgeUtils.getNextBadge(user.attendanceCount);
    final all = [...BadgeUtils.attendanceBadges, ...BadgeUtils.streakBadges];
    final earnedTypes = earned.map((b) => b.type).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('My Achievements')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Stats banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: Column(children: [
              Text(user.attendanceCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
              Text('Sessions', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ])),
            Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
            Expanded(child: Column(children: [
              Text(user.streak.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
              Text('Streak', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ])),
            Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
            Expanded(child: Column(children: [
              Text(earned.length.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
              Text('Badges', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // Next badge progress
        if (nextBadge != null) ...[
          Text('Next Badge', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: nextBadge.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(nextBadge.icon, color: nextBadge.color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nextBadge.title, style: Theme.of(context).textTheme.titleMedium),
                  Text(nextBadge.description, style: Theme.of(context).textTheme.bodySmall),
                ])),
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: user.attendanceCount / nextBadge.requiredCount,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(nextBadge.color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 6),
              Text(
                '${user.attendanceCount} / ${nextBadge.requiredCount} sessions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // All badges grid
        Text('All Badges', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12,
            mainAxisSpacing: 12, childAspectRatio: 1.1,
          ),
          itemCount: all.length,
          itemBuilder: (_, i) {
            final badge = all[i];
            final isEarned = earnedTypes.contains(badge.type);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEarned ? Colors.white : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEarned ? badge.color.withOpacity(0.3) : AppColors.divider,
                  width: isEarned ? 1.5 : 1,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? badge.color.withOpacity(0.1)
                        : AppColors.divider.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEarned ? badge.icon : Icons.lock,
                    color: isEarned ? badge.color : AppColors.textHint,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(badge.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13,
                      color: isEarned ? AppColors.textPrimary : AppColors.textHint,
                    )),
                const SizedBox(height: 4),
                Text(badge.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isEarned ? AppColors.textSecondary : AppColors.textHint,
                    )),
              ]),
            );
          },
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}