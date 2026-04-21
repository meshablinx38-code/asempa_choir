import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/safe_avatar.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _State();
}

class _State extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'),
        bottom: TabBar(controller: _tabs, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Attendance', icon: Icon(Icons.check_circle, size: 16)), Tab(text: 'Streak', icon: Icon(Icons.local_fire_department, size: 16))])),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (members) {
          final byAtt = [...members]..sort((a, b) => b.attendanceCount.compareTo(a.attendanceCount));
          final byStr = [...members]..sort((a, b) => b.streak.compareTo(a.streak));
          return TabBarView(controller: _tabs, children: [
            _LeaderList(members: byAtt, myId: me?.uid ?? '', valueGetter: (m) => m.attendanceCount, valueLabel: 'sessions', color: AppColors.success),
            _LeaderList(members: byStr, myId: me?.uid ?? '', valueGetter: (m) => m.streak, valueLabel: 'streak', color: AppColors.warning),
          ]);
        }),
    );
  }
}

class _LeaderList extends StatelessWidget {
  final List<UserModel> members; final String myId;
  final int Function(UserModel) valueGetter; final String valueLabel; final Color color;
  const _LeaderList({required this.members, required this.myId, required this.valueGetter, required this.valueLabel, required this.color});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16), itemCount: members.length,
    itemBuilder: (_, i) {
      final m = members[i]; final val = valueGetter(m); final isMe = m.uid == myId; final rank = i + 1;
      final medals = ['ðŸ¥‡','ðŸ¥ˆ','ðŸ¥‰'];
      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isMe ? AppColors.primary.withOpacity(0.06) : Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isMe ? AppColors.primary.withOpacity(0.3) : AppColors.divider.withOpacity(0.5), width: isMe ? 1.5 : 1)),
        child: Row(children: [
          SizedBox(width: 36, child: rank <= 3
              ? Text(medals[rank-1], style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)
              : Text('#' + rank.toString(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: isMe ? AppColors.primary : AppColors.textSecondary))),
          const SizedBox(width: 10),
          SafeAvatar(photoUrl: m.photoUrl, name: m.name, voicePart: m.voicePart, radius: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? m.name + ' (You)' : m.name, style: TextStyle(fontWeight: FontWeight.w600, color: isMe ? AppColors.primary : AppColors.textPrimary)),
            Text(m.voicePart.toUpperCase(), style: TextStyle(fontSize: 11, color: voicePartColor(m.voicePart), fontWeight: FontWeight.w500)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(val.toString() + ' ' + valueLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      );
    });
}
