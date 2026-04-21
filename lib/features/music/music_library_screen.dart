import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/models.dart';

class MusicLibraryScreen extends ConsumerStatefulWidget {
  const MusicLibraryScreen({super.key});
  @override
  ConsumerState<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends ConsumerState<MusicLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);
    final ytAsync = ref.watch(youtubeLinkProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Songs', icon: Icon(Icons.music_note, size: 18)),
            Tab(text: 'YouTube', icon: Icon(Icons.play_circle, size: 18)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        // â”€â”€ Songs tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        songsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (songs) => songs.isEmpty
              ? const Center(child: Text('No songs added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: songs.length,
                  itemBuilder: (_, i) => _SongCard(song: songs[i],
                      isAdmin: user?.isAdmin ?? false, ref: ref),
                ),
        ),

        // â”€â”€ YouTube tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        ytAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (links) => links.isEmpty
              ? const Center(child: Text('No YouTube links added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: links.length,
                  itemBuilder: (_, i) => _YtCard(link: links[i]),
                ),
        ),
      ]),
    );
  }
}

class _SongCard extends StatelessWidget {
  final SongModel song;
  final bool isAdmin;
  final WidgetRef ref;
  const _SongCard({required this.song, required this.isAdmin, required this.ref});

  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(song.title, style: Theme.of(context).textTheme.titleMedium),
            Text('Added by ${song.addedByName}',
                style: Theme.of(context).textTheme.bodySmall),
          ])),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => ref.read(firestoreServiceProvider).deleteSong(song.id),
            ),
        ]),
        if (song.description != null && song.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(song.description!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          if (song.youtubeUrl != null && song.youtubeUrl!.isNotEmpty)
            _LinkChip(label: 'YouTube', icon: Icons.play_circle,
                color: Colors.red, onTap: () => _launch(song.youtubeUrl)),
          if (song.telegramLink != null && song.telegramLink!.isNotEmpty)
            _LinkChip(label: 'Telegram', icon: Icons.telegram,
                color: Colors.blue, onTap: () => _launch(song.telegramLink)),
          if (song.fullSongUrl != null && song.fullSongUrl!.isNotEmpty)
            _LinkChip(label: 'Full Song', icon: Icons.audio_file,
                color: Colors.green, onTap: () => _launch(song.fullSongUrl)),
        ]),
        // Stems
        if (song.stems.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Vocal Parts:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, children: song.stems.entries
            .where((e) => e.value != null && e.value.toString().isNotEmpty)
            .map((e) => _LinkChip(
              label: e.key.toUpperCase(),
              icon: Icons.mic,
              color: voicePartColor(e.key),
              onTap: () => _launch(e.value.toString()),
            )).toList()),
        ],
      ]),
    ),
  );
}

class _LinkChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _LinkChip({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _YtCard extends StatelessWidget {
  final YouTubeLink link;
  const _YtCard({required this.link});

  Future<void> _launch() async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.play_circle, color: Colors.red, size: 28),
      ),
      title: Text(link.title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (link.description != null && link.description!.isNotEmpty)
          Text(link.description!),
        Text(DateFormat('d MMM y').format(link.addedAt),
            style: Theme.of(context).textTheme.bodySmall),
      ]),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new, color: Colors.red),
        onPressed: _launch,
      ),
      onTap: _launch,
    ),
  );
}