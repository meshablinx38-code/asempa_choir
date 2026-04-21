import 'package:flutter/material.dart';

class BadgeInfo {
  final String type, title, description;
  final IconData icon;
  final Color color;
  final int requiredCount;
  const BadgeInfo({required this.type, required this.title, required this.description, required this.icon, required this.color, required this.requiredCount});
}

class BadgeUtils {
  static const List<BadgeInfo> attendanceBadges = [
    BadgeInfo(type: 'first_checkin', title: 'First Step', description: 'Attended your first rehearsal', icon: Icons.directions_walk, color: Colors.green, requiredCount: 1),
    BadgeInfo(type: 'five_sessions', title: 'Getting Started', description: 'Attended 5 rehearsals', icon: Icons.star, color: Colors.blue, requiredCount: 5),
    BadgeInfo(type: 'ten_sessions', title: 'Committed', description: 'Attended 10 rehearsals', icon: Icons.star_half, color: Colors.orange, requiredCount: 10),
    BadgeInfo(type: 'twenty_sessions', title: 'Dedicated', description: 'Attended 20 rehearsals', icon: Icons.workspace_premium, color: Colors.purple, requiredCount: 20),
    BadgeInfo(type: 'fifty_sessions', title: 'Legend', description: 'Attended 50 rehearsals', icon: Icons.emoji_events, color: Colors.amber, requiredCount: 50),
  ];
  static const List<BadgeInfo> streakBadges = [
    BadgeInfo(type: 'streak_3', title: 'On Fire', description: '3 session streak', icon: Icons.local_fire_department, color: Colors.deepOrange, requiredCount: 3),
    BadgeInfo(type: 'streak_5', title: 'Hot Streak', description: '5 session streak', icon: Icons.bolt, color: Colors.red, requiredCount: 5),
    BadgeInfo(type: 'streak_10', title: 'Unstoppable', description: '10 session streak', icon: Icons.flash_on, color: Colors.pink, requiredCount: 10),
  ];
  static List<BadgeInfo> getEarnedBadges(int attendance, int streak) {
    final earned = <BadgeInfo>[];
    for (final b in attendanceBadges) { if (attendance >= b.requiredCount) earned.add(b); }
    for (final b in streakBadges) { if (streak >= b.requiredCount) earned.add(b); }
    return earned;
  }
  static BadgeInfo? getNextBadge(int attendance) {
    for (final b in attendanceBadges) { if (attendance < b.requiredCount) return b; }
    return null;
  }
}