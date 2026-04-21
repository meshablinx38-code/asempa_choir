import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/safe_avatar.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/user_model.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});
  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  String _search = '';
  String _filter = 'All';
  static const _filters = ['All','SOPRANO','ALTO','TENOR','BASS','PIANO','DRUMS','GUITAR'];

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Directory')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _search = ''))
                  : null,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        SizedBox(height: 44,
          child: ListView(scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: _filter == f ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: _filter == f ? FontWeight.w600 : FontWeight.normal),
              ),
            )).toList()),
        ),
        const SizedBox(height: 8),
        Expanded(child: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (members) {
            final filtered = members.where((m) {
              final matchSearch = _search.isEmpty ||
                  m.name.toLowerCase().contains(_search.toLowerCase()) ||
                  m.email.toLowerCase().contains(_search.toLowerCase());
              final matchFilter = _filter == 'All' ||
                  m.voicePart.toUpperCase() == _filter;
              return matchSearch && matchFilter;
            }).toList();

            if (filtered.isEmpty) return const Center(child: Text('No members found.'));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _MemberCard(member: filtered[i]),
            );
          },
        )),
      ]),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: voicePartColor(member.voicePart).withOpacity(0.2),
        backgroundImage: (member.photoUrl != null && member.photoUrl!.isNotEmpty)
            ? NetworkImage(member.photoUrl!) : null,
        child: (member.photoUrl == null || member.photoUrl!.isEmpty)
            ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(color: voicePartColor(member.voicePart),
                    fontWeight: FontWeight.w600))
            : null,
      ),
      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: voicePartColor(member.voicePart).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(member.voicePart.toUpperCase(),
                style: TextStyle(color: voicePartColor(member.voicePart),
                    fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          if (member.isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('LEADER', style: TextStyle(color: Colors.orange,
                  fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        if (member.hostel != null && member.hostel!.isNotEmpty)
          Text(member.hostel!, style: Theme.of(context).textTheme.bodySmall),
      ]),
    ),
  );
}