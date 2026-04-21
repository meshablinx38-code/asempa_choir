$fix = @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/safe_avatar.dart';
import '../../providers/providers.dart';
import '../../models/phase2_models.dart';
import '../../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TESTIMONIES
// ═══════════════════════════════════════════════════════════════════════════
'@
# We write each file individually using WriteAllText to avoid PowerShell interpolation issues

$testimony = 'import' + " 'package:flutter/material.dart';" + [System.Environment]::NewLine
$testimony += 'import' + " 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$testimony += 'import' + " 'package:cloud_firestore/cloud_firestore.dart';" + [System.Environment]::NewLine
$testimony += 'import' + " 'package:intl/intl.dart';" + [System.Environment]::NewLine
$testimony += 'import' + " 'package:uuid/uuid.dart';" + [System.Environment]::NewLine
$testimony += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$testimony += "import '../../shared/widgets/safe_avatar.dart';" + [System.Environment]::NewLine
$testimony += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$testimony += "import '../../models/phase2_models.dart';" + [System.Environment]::NewLine
$testimony += [System.Environment]::NewLine
$testimony += 'final testimoniesProvider = StreamProvider<List<TestimonyModel>>((ref) {' + [System.Environment]::NewLine
$testimony += "  return FirebaseFirestore.instance.collection('testimonies').where('isApproved', isEqualTo: true).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(TestimonyModel.fromFirestore).toList());" + [System.Environment]::NewLine
$testimony += '});' + [System.Environment]::NewLine
$testimony += [System.Environment]::NewLine
$testimony += 'class TestimoniesScreen extends ConsumerWidget {' + [System.Environment]::NewLine
$testimony += '  const TestimoniesScreen({super.key});' + [System.Environment]::NewLine
$testimony += '  @override' + [System.Environment]::NewLine
$testimony += '  Widget build(BuildContext context, WidgetRef ref) {' + [System.Environment]::NewLine
$testimony += '    final async = ref.watch(testimoniesProvider);' + [System.Environment]::NewLine
$testimony += '    final user = ref.watch(currentUserProvider).valueOrNull;' + [System.Environment]::NewLine
$testimony += '    return Scaffold(' + [System.Environment]::NewLine
$testimony += "      appBar: AppBar(title: const Text('Testimonies'))," + [System.Environment]::NewLine
$testimony += '      body: async.when(' + [System.Environment]::NewLine
$testimony += '        loading: () => const Center(child: CircularProgressIndicator()),' + [System.Environment]::NewLine
$testimony += '        error: (e, _) => Center(child: Text(e.toString())),' + [System.Environment]::NewLine
$testimony += '        data: (list) => list.isEmpty' + [System.Environment]::NewLine
$testimony += '            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [' + [System.Environment]::NewLine
$testimony += '                const Icon(Icons.volunteer_activism, size: 80, color: AppColors.textHint),' + [System.Environment]::NewLine
$testimony += '                const SizedBox(height: 16),' + [System.Environment]::NewLine
$testimony += "                Text('No testimonies yet', style: Theme.of(context).textTheme.headlineSmall)," + [System.Environment]::NewLine
$testimony += '                const SizedBox(height: 8),' + [System.Environment]::NewLine
$testimony += "                Text('Be the first to share what God has done!', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)," + [System.Environment]::NewLine
$testimony += '              ]))' + [System.Environment]::NewLine
$testimony += '            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,' + [System.Environment]::NewLine
$testimony += "                itemBuilder: (_, i) => _TestimonyCard(testimony: list[i], currentUserId: user?.uid ?? '')))," + [System.Environment]::NewLine
$testimony += '      floatingActionButton: FloatingActionButton.extended(' + [System.Environment]::NewLine
$testimony += '        onPressed: () => _showPostDialog(context, ref, user),' + [System.Environment]::NewLine
$testimony += "        icon: const Icon(Icons.add), label: const Text('Share Testimony')," + [System.Environment]::NewLine
$testimony += '        backgroundColor: AppColors.primary),' + [System.Environment]::NewLine
$testimony += '    );' + [System.Environment]::NewLine
$testimony += '  }' + [System.Environment]::NewLine
$testimony += [System.Environment]::NewLine
$testimony += '  void _showPostDialog(BuildContext ctx, WidgetRef ref, user) {' + [System.Environment]::NewLine
$testimony += '    if (user == null) return;' + [System.Environment]::NewLine
$testimony += '    final titleCtrl = TextEditingController();' + [System.Environment]::NewLine
$testimony += '    final contentCtrl = TextEditingController();' + [System.Environment]::NewLine
$testimony += '    bool anon = false;' + [System.Environment]::NewLine
$testimony += '    showModalBottomSheet(context: ctx, isScrollControlled: true,' + [System.Environment]::NewLine
$testimony += '        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),' + [System.Environment]::NewLine
$testimony += '        builder: (c) => StatefulBuilder(builder: (c, set) => Padding(' + [System.Environment]::NewLine
$testimony += '          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),' + [System.Environment]::NewLine
$testimony += '          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [' + [System.Environment]::NewLine
$testimony += "            Text('Share Your Testimony', style: Theme.of(ctx).textTheme.headlineSmall)," + [System.Environment]::NewLine
$testimony += '            const SizedBox(height: 16),' + [System.Environment]::NewLine
$testimony += "            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title'))," + [System.Environment]::NewLine
$testimony += '            const SizedBox(height: 12),' + [System.Environment]::NewLine
$testimony += "            TextField(controller: contentCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Your testimony', alignLabelWithHint: true))," + [System.Environment]::NewLine
$testimony += '            const SizedBox(height: 8),' + [System.Environment]::NewLine
$testimony += "            Row(children: [Switch(value: anon, onChanged: (v) => set(() => anon = v)), const Text('Post anonymously')])," + [System.Environment]::NewLine
$testimony += '            const SizedBox(height: 8),' + [System.Environment]::NewLine
$testimony += "            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Text('Your testimony will be reviewed before appearing.', style: TextStyle(fontSize: 12, color: AppColors.info)))," + [System.Environment]::NewLine
$testimony += '            const SizedBox(height: 16),' + [System.Environment]::NewLine
$testimony += '            ElevatedButton(onPressed: () async {' + [System.Environment]::NewLine
$testimony += '              if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;' + [System.Environment]::NewLine
$testimony += '              final t = TestimonyModel(id: const Uuid().v4(), userId: user.uid, fullName: anon ? '
$testimony += "'Anonymous' : user.name, voicePart: user.voicePart, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), isAnonymous: anon, isApproved: false, createdAt: DateTime.now());" + [System.Environment]::NewLine
$testimony += "              await FirebaseFirestore.instance.collection('testimonies').doc(t.id).set(t.toFirestore());" + [System.Environment]::NewLine
$testimony += "              if (c.mounted) { Navigator.pop(c); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Testimony submitted for review!'))); }" + [System.Environment]::NewLine
$testimony += "            }, child: const Text('Submit for Review'))," + [System.Environment]::NewLine
$testimony += '          ]),' + [System.Environment]::NewLine
$testimony += '        )));' + [System.Environment]::NewLine
$testimony += '  }' + [System.Environment]::NewLine
$testimony += '}' + [System.Environment]::NewLine
$testimony += [System.Environment]::NewLine
$testimony += 'class _TestimonyCard extends StatelessWidget {' + [System.Environment]::NewLine
$testimony += '  final TestimonyModel testimony; final String currentUserId;' + [System.Environment]::NewLine
$testimony += '  const _TestimonyCard({required this.testimony, required this.currentUserId});' + [System.Environment]::NewLine
$testimony += '  @override' + [System.Environment]::NewLine
$testimony += '  Widget build(BuildContext context) {' + [System.Environment]::NewLine
$testimony += '    final hasLiked = testimony.likes.contains(currentUserId);' + [System.Environment]::NewLine
$testimony += '    return Card(margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [' + [System.Environment]::NewLine
$testimony += '      Row(children: [' + [System.Environment]::NewLine
$testimony += "        SafeAvatar(photoUrl: null, name: testimony.fullName, voicePart: testimony.voicePart, radius: 22)," + [System.Environment]::NewLine
$testimony += '        const SizedBox(width: 12),' + [System.Environment]::NewLine
$testimony += '        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [' + [System.Environment]::NewLine
$testimony += "          Text(testimony.isAnonymous ? 'Anonymous' : testimony.fullName, style: Theme.of(context).textTheme.titleMedium)," + [System.Environment]::NewLine
$testimony += "          Text(DateFormat('d MMM y').format(testimony.createdAt), style: Theme.of(context).textTheme.bodySmall)," + [System.Environment]::NewLine
$testimony += '        ])),' + [System.Environment]::NewLine
$testimony += '        const Icon(Icons.volunteer_activism, color: Colors.pink),' + [System.Environment]::NewLine
$testimony += '      ]),' + [System.Environment]::NewLine
$testimony += '      const SizedBox(height: 12),' + [System.Environment]::NewLine
$testimony += '      Text(testimony.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),' + [System.Environment]::NewLine
$testimony += '      const SizedBox(height: 6),' + [System.Environment]::NewLine
$testimony += '      Text(testimony.content, style: Theme.of(context).textTheme.bodyMedium),' + [System.Environment]::NewLine
$testimony += '      const SizedBox(height: 12),' + [System.Environment]::NewLine
$testimony += '      GestureDetector(' + [System.Environment]::NewLine
$testimony += '        onTap: () async {' + [System.Environment]::NewLine
$testimony += "          final r = FirebaseFirestore.instance.collection('testimonies').doc(testimony.id);" + [System.Environment]::NewLine
$testimony += "          if (hasLiked) { await r.update({'likes': FieldValue.arrayRemove([currentUserId])}); }" + [System.Environment]::NewLine
$testimony += "          else { await r.update({'likes': FieldValue.arrayUnion([currentUserId])}); }" + [System.Environment]::NewLine
$testimony += '        },' + [System.Environment]::NewLine
$testimony += '        child: Row(children: [' + [System.Environment]::NewLine
$testimony += '          Icon(hasLiked ? Icons.favorite : Icons.favorite_border, color: hasLiked ? Colors.red : AppColors.textHint, size: 20),' + [System.Environment]::NewLine
$testimony += '          const SizedBox(width: 4),' + [System.Environment]::NewLine
$testimony += '          Text(testimony.likes.length.toString(), style: TextStyle(color: hasLiked ? Colors.red : AppColors.textHint)),' + [System.Environment]::NewLine
$testimony += '        ]),' + [System.Environment]::NewLine
$testimony += '      ),' + [System.Environment]::NewLine
$testimony += '    ])));' + [System.Environment]::NewLine
$testimony += '  }' + [System.Environment]::NewLine
$testimony += '}' + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\features\testimonies\testimonies_screen.dart", $testimony, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: testimonies_screen.dart" -ForegroundColor Cyan

# ── gallery_screen.dart ───────────────────────────────────────────────────────
$gallery = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$gallery += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$gallery += "import 'package:cloud_firestore/cloud_firestore.dart';" + [System.Environment]::NewLine
$gallery += "import 'package:uuid/uuid.dart';" + [System.Environment]::NewLine
$gallery += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$gallery += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$gallery += "import '../../models/phase2_models.dart';" + [System.Environment]::NewLine
$gallery += [System.Environment]::NewLine
$gallery += "final galleryProvider = StreamProvider<List<GalleryPhoto>>((ref) {" + [System.Environment]::NewLine
$gallery += "  return FirebaseFirestore.instance.collection('gallery').orderBy('uploadedAt', descending: true).snapshots().map((s) => s.docs.map(GalleryPhoto.fromFirestore).toList());" + [System.Environment]::NewLine
$gallery += "});" + [System.Environment]::NewLine
$gallery += [System.Environment]::NewLine
$gallery += "class GalleryScreen extends ConsumerWidget {" + [System.Environment]::NewLine
$gallery += "  const GalleryScreen({super.key});" + [System.Environment]::NewLine
$gallery += "  @override" + [System.Environment]::NewLine
$gallery += "  Widget build(BuildContext context, WidgetRef ref) {" + [System.Environment]::NewLine
$gallery += "    final async = ref.watch(galleryProvider);" + [System.Environment]::NewLine
$gallery += "    final user = ref.watch(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$gallery += "    return Scaffold(" + [System.Environment]::NewLine
$gallery += "      appBar: AppBar(title: const Text('Photo Gallery'))," + [System.Environment]::NewLine
$gallery += "      body: async.when(" + [System.Environment]::NewLine
$gallery += "        loading: () => const Center(child: CircularProgressIndicator())," + [System.Environment]::NewLine
$gallery += "        error: (e, _) => Center(child: Text(e.toString()))," + [System.Environment]::NewLine
$gallery += "        data: (photos) => photos.isEmpty" + [System.Environment]::NewLine
$gallery += "            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [" + [System.Environment]::NewLine
$gallery += "                const Icon(Icons.photo_library, size: 80, color: AppColors.textHint)," + [System.Environment]::NewLine
$gallery += "                const SizedBox(height: 16)," + [System.Environment]::NewLine
$gallery += "                Text('No photos yet', style: Theme.of(context).textTheme.headlineSmall)," + [System.Environment]::NewLine
$gallery += "                const SizedBox(height: 8)," + [System.Environment]::NewLine
$gallery += "                Text('Share memories from rehearsals!', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)," + [System.Environment]::NewLine
$gallery += "              ]))" + [System.Environment]::NewLine
$gallery += "            : GridView.builder(padding: const EdgeInsets.all(8)," + [System.Environment]::NewLine
$gallery += "                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85)," + [System.Environment]::NewLine
$gallery += "                itemCount: photos.length," + [System.Environment]::NewLine
$gallery += "                itemBuilder: (_, i) => _PhotoCard(photo: photos[i], currentUserId: user?.uid ?? '')))," + [System.Environment]::NewLine
$gallery += "      floatingActionButton: user != null ? FloatingActionButton.extended(" + [System.Environment]::NewLine
$gallery += "          onPressed: () => _showAdd(context, ref, user)," + [System.Environment]::NewLine
$gallery += "          icon: const Icon(Icons.add_photo_alternate), label: const Text('Add Photo')," + [System.Environment]::NewLine
$gallery += "          backgroundColor: AppColors.primary) : null," + [System.Environment]::NewLine
$gallery += "    );" + [System.Environment]::NewLine
$gallery += "  }" + [System.Environment]::NewLine
$gallery += [System.Environment]::NewLine
$gallery += "  void _showAdd(BuildContext ctx, WidgetRef ref, user) {" + [System.Environment]::NewLine
$gallery += "    final urlCtrl = TextEditingController();" + [System.Environment]::NewLine
$gallery += "    final capCtrl = TextEditingController();" + [System.Environment]::NewLine
$gallery += "    showModalBottomSheet(context: ctx, isScrollControlled: true," + [System.Environment]::NewLine
$gallery += "        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))," + [System.Environment]::NewLine
$gallery += "        builder: (c) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24)," + [System.Environment]::NewLine
$gallery += "          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [" + [System.Environment]::NewLine
$gallery += "            Text('Add Photo', style: Theme.of(ctx).textTheme.headlineSmall)," + [System.Environment]::NewLine
$gallery += "            const SizedBox(height: 16)," + [System.Environment]::NewLine
$gallery += "            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://i.ibb.co/...', prefixIcon: Icon(Icons.link)))," + [System.Environment]::NewLine
$gallery += "            const SizedBox(height: 12)," + [System.Environment]::NewLine
$gallery += "            TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Caption (optional)'))," + [System.Environment]::NewLine
$gallery += "            const SizedBox(height: 16)," + [System.Environment]::NewLine
$gallery += "            ElevatedButton(onPressed: () async {" + [System.Environment]::NewLine
$gallery += "              if (urlCtrl.text.trim().isEmpty) return;" + [System.Environment]::NewLine
$gallery += "              final p = GalleryPhoto(id: const Uuid().v4(), imageUrl: urlCtrl.text.trim(), caption: capCtrl.text.trim(), uploadedBy: user.uid, uploadedByName: user.name, uploadedAt: DateTime.now());" + [System.Environment]::NewLine
$gallery += "              await FirebaseFirestore.instance.collection('gallery').doc(p.id).set(p.toFirestore());" + [System.Environment]::NewLine
$gallery += "              if (c.mounted) Navigator.pop(c);" + [System.Environment]::NewLine
$gallery += "            }, child: const Text('Add to Gallery'))," + [System.Environment]::NewLine
$gallery += "          ])));" + [System.Environment]::NewLine
$gallery += "  }" + [System.Environment]::NewLine
$gallery += "}" + [System.Environment]::NewLine
$gallery += [System.Environment]::NewLine
$gallery += "class _PhotoCard extends StatelessWidget {" + [System.Environment]::NewLine
$gallery += "  final GalleryPhoto photo; final String currentUserId;" + [System.Environment]::NewLine
$gallery += "  const _PhotoCard({required this.photo, required this.currentUserId});" + [System.Environment]::NewLine
$gallery += "  @override" + [System.Environment]::NewLine
$gallery += "  Widget build(BuildContext context) {" + [System.Environment]::NewLine
$gallery += "    final hasLiked = photo.likes.contains(currentUserId);" + [System.Environment]::NewLine
$gallery += "    return GestureDetector(" + [System.Environment]::NewLine
$gallery += "      onTap: () => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero," + [System.Environment]::NewLine
$gallery += "          child: Stack(children: [" + [System.Environment]::NewLine
$gallery += "            Center(child: Image.network(photo.imageUrl, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64)))," + [System.Environment]::NewLine
$gallery += "            Positioned(top: 40, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))," + [System.Environment]::NewLine
$gallery += "            if (photo.caption.isNotEmpty) Positioned(bottom: 40, left: 16, right: 16, child: Text(photo.caption, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center))," + [System.Environment]::NewLine
$gallery += "          ])))," + [System.Environment]::NewLine
$gallery += "      child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12))," + [System.Environment]::NewLine
$gallery += "        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [" + [System.Environment]::NewLine
$gallery += "          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12))," + [System.Environment]::NewLine
$gallery += "              child: Image.network(photo.imageUrl, width: double.infinity, fit: BoxFit.cover," + [System.Environment]::NewLine
$gallery += "                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: AppColors.textHint, size: 48)))))," + [System.Environment]::NewLine
$gallery += "          Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [" + [System.Environment]::NewLine
$gallery += "            if (photo.caption.isNotEmpty) Text(photo.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))," + [System.Environment]::NewLine
$gallery += "            Row(children: [" + [System.Environment]::NewLine
$gallery += "              GestureDetector(" + [System.Environment]::NewLine
$gallery += "                onTap: () async {" + [System.Environment]::NewLine
$gallery += "                  final r = FirebaseFirestore.instance.collection('gallery').doc(photo.id);" + [System.Environment]::NewLine
$gallery += "                  if (hasLiked) { await r.update({'likes': FieldValue.arrayRemove([currentUserId])}); }" + [System.Environment]::NewLine
$gallery += "                  else { await r.update({'likes': FieldValue.arrayUnion([currentUserId])}); }" + [System.Environment]::NewLine
$gallery += "                }," + [System.Environment]::NewLine
$gallery += "                child: Row(children: [" + [System.Environment]::NewLine
$gallery += "                  Icon(hasLiked ? Icons.favorite : Icons.favorite_border, size: 16, color: hasLiked ? Colors.red : AppColors.textHint)," + [System.Environment]::NewLine
$gallery += "                  const SizedBox(width: 3)," + [System.Environment]::NewLine
$gallery += "                  Text(photo.likes.length.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textHint))," + [System.Environment]::NewLine
$gallery += "                ])," + [System.Environment]::NewLine
$gallery += "              )," + [System.Environment]::NewLine
$gallery += "              const Spacer()," + [System.Environment]::NewLine
$gallery += "              Text(photo.uploadedByName.split(' ').first, style: const TextStyle(fontSize: 11, color: AppColors.textHint))," + [System.Environment]::NewLine
$gallery += "            ])," + [System.Environment]::NewLine
$gallery += "          ]))," + [System.Environment]::NewLine
$gallery += "        ])," + [System.Environment]::NewLine
$gallery += "      )," + [System.Environment]::NewLine
$gallery += "    );" + [System.Environment]::NewLine
$gallery += "  }" + [System.Environment]::NewLine
$gallery += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\features\gallery\gallery_screen.dart", $gallery, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: gallery_screen.dart" -ForegroundColor Cyan

# ── leaderboard_screen.dart ───────────────────────────────────────────────────
$leader = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$leader += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$leader += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$leader += "import '../../shared/widgets/safe_avatar.dart';" + [System.Environment]::NewLine
$leader += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$leader += "import '../../models/user_model.dart';" + [System.Environment]::NewLine
$leader += [System.Environment]::NewLine
$leader += "class LeaderboardScreen extends ConsumerStatefulWidget {" + [System.Environment]::NewLine
$leader += "  const LeaderboardScreen({super.key});" + [System.Environment]::NewLine
$leader += "  @override" + [System.Environment]::NewLine
$leader += "  ConsumerState<LeaderboardScreen> createState() => _State();" + [System.Environment]::NewLine
$leader += "}" + [System.Environment]::NewLine
$leader += [System.Environment]::NewLine
$leader += "class _State extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {" + [System.Environment]::NewLine
$leader += "  late TabController _tabs;" + [System.Environment]::NewLine
$leader += "  @override" + [System.Environment]::NewLine
$leader += "  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }" + [System.Environment]::NewLine
$leader += "  @override" + [System.Environment]::NewLine
$leader += "  void dispose() { _tabs.dispose(); super.dispose(); }" + [System.Environment]::NewLine
$leader += [System.Environment]::NewLine
$leader += "  @override" + [System.Environment]::NewLine
$leader += "  Widget build(BuildContext context) {" + [System.Environment]::NewLine
$leader += "    final membersAsync = ref.watch(allMembersProvider);" + [System.Environment]::NewLine
$leader += "    final me = ref.watch(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$leader += "    return Scaffold(" + [System.Environment]::NewLine
$leader += "      appBar: AppBar(title: const Text('Leaderboard')," + [System.Environment]::NewLine
$leader += "        bottom: TabBar(controller: _tabs, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60," + [System.Environment]::NewLine
$leader += "          tabs: const [Tab(text: 'Attendance', icon: Icon(Icons.check_circle, size: 16)), Tab(text: 'Streak', icon: Icon(Icons.local_fire_department, size: 16))]))," + [System.Environment]::NewLine
$leader += "      body: membersAsync.when(" + [System.Environment]::NewLine
$leader += "        loading: () => const Center(child: CircularProgressIndicator())," + [System.Environment]::NewLine
$leader += "        error: (e, _) => Center(child: Text(e.toString()))," + [System.Environment]::NewLine
$leader += "        data: (members) {" + [System.Environment]::NewLine
$leader += "          final byAtt = [...members]..sort((a, b) => b.attendanceCount.compareTo(a.attendanceCount));" + [System.Environment]::NewLine
$leader += "          final byStr = [...members]..sort((a, b) => b.streak.compareTo(a.streak));" + [System.Environment]::NewLine
$leader += "          return TabBarView(controller: _tabs, children: [" + [System.Environment]::NewLine
$leader += "            _LeaderList(members: byAtt, myId: me?.uid ?? '', valueGetter: (m) => m.attendanceCount, valueLabel: 'sessions', color: AppColors.success)," + [System.Environment]::NewLine
$leader += "            _LeaderList(members: byStr, myId: me?.uid ?? '', valueGetter: (m) => m.streak, valueLabel: 'streak', color: AppColors.warning)," + [System.Environment]::NewLine
$leader += "          ]);" + [System.Environment]::NewLine
$leader += "        })," + [System.Environment]::NewLine
$leader += "    );" + [System.Environment]::NewLine
$leader += "  }" + [System.Environment]::NewLine
$leader += "}" + [System.Environment]::NewLine
$leader += [System.Environment]::NewLine
$leader += "class _LeaderList extends StatelessWidget {" + [System.Environment]::NewLine
$leader += "  final List<UserModel> members; final String myId;" + [System.Environment]::NewLine
$leader += "  final int Function(UserModel) valueGetter; final String valueLabel; final Color color;" + [System.Environment]::NewLine
$leader += "  const _LeaderList({required this.members, required this.myId, required this.valueGetter, required this.valueLabel, required this.color});" + [System.Environment]::NewLine
$leader += [System.Environment]::NewLine
$leader += "  @override" + [System.Environment]::NewLine
$leader += "  Widget build(BuildContext context) => ListView.builder(" + [System.Environment]::NewLine
$leader += "    padding: const EdgeInsets.all(16), itemCount: members.length," + [System.Environment]::NewLine
$leader += "    itemBuilder: (_, i) {" + [System.Environment]::NewLine
$leader += "      final m = members[i]; final val = valueGetter(m); final isMe = m.uid == myId; final rank = i + 1;" + [System.Environment]::NewLine
$leader += "      final medals = ['🥇','🥈','🥉'];" + [System.Environment]::NewLine
$leader += "      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12)," + [System.Environment]::NewLine
$leader += "        decoration: BoxDecoration(color: isMe ? AppColors.primary.withOpacity(0.06) : Colors.white, borderRadius: BorderRadius.circular(12)," + [System.Environment]::NewLine
$leader += "            border: Border.all(color: isMe ? AppColors.primary.withOpacity(0.3) : AppColors.divider.withOpacity(0.5), width: isMe ? 1.5 : 1))," + [System.Environment]::NewLine
$leader += "        child: Row(children: [" + [System.Environment]::NewLine
$leader += "          SizedBox(width: 36, child: rank <= 3" + [System.Environment]::NewLine
$leader += "              ? Text(medals[rank-1], style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)" + [System.Environment]::NewLine
$leader += "              : Text('#' + rank.toString(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: isMe ? AppColors.primary : AppColors.textSecondary)))," + [System.Environment]::NewLine
$leader += "          const SizedBox(width: 10)," + [System.Environment]::NewLine
$leader += "          SafeAvatar(photoUrl: m.photoUrl, name: m.name, voicePart: m.voicePart, radius: 20)," + [System.Environment]::NewLine
$leader += "          const SizedBox(width: 12)," + [System.Environment]::NewLine
$leader += "          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [" + [System.Environment]::NewLine
$leader += "            Text(isMe ? m.name + ' (You)' : m.name, style: TextStyle(fontWeight: FontWeight.w600, color: isMe ? AppColors.primary : AppColors.textPrimary))," + [System.Environment]::NewLine
$leader += "            Text(m.voicePart.toUpperCase(), style: TextStyle(fontSize: 11, color: voicePartColor(m.voicePart), fontWeight: FontWeight.w500))," + [System.Environment]::NewLine
$leader += "          ]))," + [System.Environment]::NewLine
$leader += "          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)," + [System.Environment]::NewLine
$leader += "              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20))," + [System.Environment]::NewLine
$leader += "              child: Text(val.toString() + ' ' + valueLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)))," + [System.Environment]::NewLine
$leader += "        ])," + [System.Environment]::NewLine
$leader += "      );" + [System.Environment]::NewLine
$leader += "    });" + [System.Environment]::NewLine
$leader += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\features\leaderboard\leaderboard_screen.dart", $leader, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: leaderboard_screen.dart" -ForegroundColor Cyan

# ── polls_screen.dart ─────────────────────────────────────────────────────────
$polls = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$polls += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$polls += "import 'package:cloud_firestore/cloud_firestore.dart';" + [System.Environment]::NewLine
$polls += "import 'package:uuid/uuid.dart';" + [System.Environment]::NewLine
$polls += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$polls += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$polls += "import '../../models/phase2_models.dart';" + [System.Environment]::NewLine
$polls += [System.Environment]::NewLine
$polls += "final pollsProvider = StreamProvider<List<PollModel>>((ref) {" + [System.Environment]::NewLine
$polls += "  return FirebaseFirestore.instance.collection('polls').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(PollModel.fromFirestore).toList());" + [System.Environment]::NewLine
$polls += "});" + [System.Environment]::NewLine
$polls += [System.Environment]::NewLine
$polls += "class PollsScreen extends ConsumerWidget {" + [System.Environment]::NewLine
$polls += "  const PollsScreen({super.key});" + [System.Environment]::NewLine
$polls += "  @override" + [System.Environment]::NewLine
$polls += "  Widget build(BuildContext context, WidgetRef ref) {" + [System.Environment]::NewLine
$polls += "    final async = ref.watch(pollsProvider);" + [System.Environment]::NewLine
$polls += "    final user = ref.watch(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$polls += "    return Scaffold(" + [System.Environment]::NewLine
$polls += "      appBar: AppBar(title: const Text('Polls & Surveys'))," + [System.Environment]::NewLine
$polls += "      body: async.when(" + [System.Environment]::NewLine
$polls += "        loading: () => const Center(child: CircularProgressIndicator())," + [System.Environment]::NewLine
$polls += "        error: (e, _) => Center(child: Text(e.toString()))," + [System.Environment]::NewLine
$polls += "        data: (polls) => polls.isEmpty" + [System.Environment]::NewLine
$polls += "            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [" + [System.Environment]::NewLine
$polls += "                const Icon(Icons.poll, size: 80, color: AppColors.textHint)," + [System.Environment]::NewLine
$polls += "                const SizedBox(height: 16)," + [System.Environment]::NewLine
$polls += "                Text('No active polls', style: Theme.of(context).textTheme.headlineSmall)," + [System.Environment]::NewLine
$polls += "              ]))" + [System.Environment]::NewLine
$polls += "            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: polls.length," + [System.Environment]::NewLine
$polls += "                itemBuilder: (_, i) => _PollCard(poll: polls[i], currentUserId: user?.uid ?? '')))," + [System.Environment]::NewLine
$polls += "      floatingActionButton: user?.isAdmin == true" + [System.Environment]::NewLine
$polls += "          ? FloatingActionButton.extended(onPressed: () => _showCreate(context, ref, user!.uid)," + [System.Environment]::NewLine
$polls += "              icon: const Icon(Icons.add), label: const Text('Create Poll'), backgroundColor: AppColors.primary)" + [System.Environment]::NewLine
$polls += "          : null," + [System.Environment]::NewLine
$polls += "    );" + [System.Environment]::NewLine
$polls += "  }" + [System.Environment]::NewLine
$polls += [System.Environment]::NewLine
$polls += "  void _showCreate(BuildContext ctx, WidgetRef ref, String uid) {" + [System.Environment]::NewLine
$polls += "    final q = TextEditingController();" + [System.Environment]::NewLine
$polls += "    final opts = List.generate(4, (i) => TextEditingController(text: i == 0 ? 'Yes' : i == 1 ? 'No' : ''));" + [System.Environment]::NewLine
$polls += "    showModalBottomSheet(context: ctx, isScrollControlled: true," + [System.Environment]::NewLine
$polls += "        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))," + [System.Environment]::NewLine
$polls += "        builder: (c) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24)," + [System.Environment]::NewLine
$polls += "          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [" + [System.Environment]::NewLine
$polls += "            Text('Create Poll', style: Theme.of(ctx).textTheme.headlineSmall)," + [System.Environment]::NewLine
$polls += "            const SizedBox(height: 16)," + [System.Environment]::NewLine
$polls += "            TextField(controller: q, maxLines: 2, decoration: const InputDecoration(labelText: 'Question', alignLabelWithHint: true))," + [System.Environment]::NewLine
$polls += "            const SizedBox(height: 12)," + [System.Environment]::NewLine
$polls += "            ...List.generate(4, (i) => Padding(padding: const EdgeInsets.only(bottom: 8)," + [System.Environment]::NewLine
$polls += "                child: TextField(controller: opts[i], decoration: InputDecoration(labelText: 'Option ' + (i+1).toString() + (i >= 2 ? ' (optional)' : '')))))," + [System.Environment]::NewLine
$polls += "            const SizedBox(height: 16)," + [System.Environment]::NewLine
$polls += "            ElevatedButton(onPressed: () async {" + [System.Environment]::NewLine
$polls += "              if (q.text.isEmpty || opts[0].text.isEmpty || opts[1].text.isEmpty) return;" + [System.Environment]::NewLine
$polls += "              final options = [opts[0].text.trim(), opts[1].text.trim(), ...opts.skip(2).map((o) => o.text.trim()).where((t) => t.isNotEmpty)];" + [System.Environment]::NewLine
$polls += "              final votes = {for (final o in options) o: <String>[]};" + [System.Environment]::NewLine
$polls += "              final poll = PollModel(id: const Uuid().v4(), question: q.text.trim(), createdBy: uid, options: options, votes: votes, createdAt: DateTime.now());" + [System.Environment]::NewLine
$polls += "              await FirebaseFirestore.instance.collection('polls').doc(poll.id).set(poll.toFirestore());" + [System.Environment]::NewLine
$polls += "              if (c.mounted) Navigator.pop(c);" + [System.Environment]::NewLine
$polls += "            }, child: const Text('Publish Poll'))," + [System.Environment]::NewLine
$polls += "          ]))));" + [System.Environment]::NewLine
$polls += "  }" + [System.Environment]::NewLine
$polls += "}" + [System.Environment]::NewLine
$polls += [System.Environment]::NewLine
$polls += "class _PollCard extends StatelessWidget {" + [System.Environment]::NewLine
$polls += "  final PollModel poll; final String currentUserId;" + [System.Environment]::NewLine
$polls += "  const _PollCard({required this.poll, required this.currentUserId});" + [System.Environment]::NewLine
$polls += "  @override" + [System.Environment]::NewLine
$polls += "  Widget build(BuildContext context) {" + [System.Environment]::NewLine
$polls += "    final userVote = poll.userVote(currentUserId);" + [System.Environment]::NewLine
$polls += "    final hasVoted = userVote != null;" + [System.Environment]::NewLine
$polls += "    return Card(margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [" + [System.Environment]::NewLine
$polls += "      Row(children: [const Icon(Icons.poll, color: AppColors.primary, size: 20), const SizedBox(width: 8), Expanded(child: Text(poll.question, style: Theme.of(context).textTheme.titleMedium))])," + [System.Environment]::NewLine
$polls += "      const SizedBox(height: 4)," + [System.Environment]::NewLine
$polls += "      Text(poll.totalVotes.toString() + ' vote' + (poll.totalVotes == 1 ? '' : 's'), style: Theme.of(context).textTheme.bodySmall)," + [System.Environment]::NewLine
$polls += "      const SizedBox(height: 12)," + [System.Environment]::NewLine
$polls += "      ...poll.options.map((option) {" + [System.Environment]::NewLine
$polls += "        final votes = poll.votesFor(option);" + [System.Environment]::NewLine
$polls += "        final total = poll.totalVotes;" + [System.Environment]::NewLine
$polls += "        final pct = total > 0 ? votes / total : 0.0;" + [System.Environment]::NewLine
$polls += "        final isSelected = userVote == option;" + [System.Environment]::NewLine
$polls += "        return GestureDetector(" + [System.Environment]::NewLine
$polls += "          onTap: hasVoted ? null : () async {" + [System.Environment]::NewLine
$polls += "            final update = <String, dynamic>{};" + [System.Environment]::NewLine
$polls += "            update['votes.' + option] = FieldValue.arrayUnion([currentUserId]);" + [System.Environment]::NewLine
$polls += "            await FirebaseFirestore.instance.collection('polls').doc(poll.id).update(update);" + [System.Environment]::NewLine
$polls += "          }," + [System.Environment]::NewLine
$polls += "          child: Container(margin: const EdgeInsets.only(bottom: 8), child: Stack(children: [" + [System.Environment]::NewLine
$polls += "            Container(height: 44, decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 1.5 : 1)))," + [System.Environment]::NewLine
$polls += "            if (hasVoted) FractionallySizedBox(widthFactor: pct, child: Container(height: 44, decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.divider.withOpacity(0.5), borderRadius: BorderRadius.circular(10))))," + [System.Environment]::NewLine
$polls += "            Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [" + [System.Environment]::NewLine
$polls += "              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 16)," + [System.Environment]::NewLine
$polls += "              if (isSelected) const SizedBox(width: 6)," + [System.Environment]::NewLine
$polls += "              Expanded(child: Text(option, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.textPrimary)))," + [System.Environment]::NewLine
$polls += "              if (hasVoted) Text((pct * 100).round().toString() + '%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary))," + [System.Environment]::NewLine
$polls += "            ])))," + [System.Environment]::NewLine
$polls += "          ])));" + [System.Environment]::NewLine
$polls += "      })," + [System.Environment]::NewLine
$polls += "      if (!hasVoted) Text('Tap an option to vote', style: Theme.of(context).textTheme.bodySmall)," + [System.Environment]::NewLine
$polls += "    ])));" + [System.Environment]::NewLine
$polls += "  }" + [System.Environment]::NewLine
$polls += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\features\polls\polls_screen.dart", $polls, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: polls_screen.dart" -ForegroundColor Cyan

# ── suggestion_box_screen.dart ────────────────────────────────────────────────
$sugg = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$sugg += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$sugg += "import 'package:cloud_firestore/cloud_firestore.dart';" + [System.Environment]::NewLine
$sugg += "import 'package:intl/intl.dart';" + [System.Environment]::NewLine
$sugg += "import 'package:uuid/uuid.dart';" + [System.Environment]::NewLine
$sugg += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$sugg += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$sugg += "import '../../models/phase2_models.dart';" + [System.Environment]::NewLine
$sugg += [System.Environment]::NewLine
$sugg += "final suggestionsProvider = StreamProvider<List<SuggestionModel>>((ref) {" + [System.Environment]::NewLine
$sugg += "  return FirebaseFirestore.instance.collection('suggestions').orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(SuggestionModel.fromFirestore).toList());" + [System.Environment]::NewLine
$sugg += "});" + [System.Environment]::NewLine
$sugg += [System.Environment]::NewLine
$sugg += "class SuggestionBoxScreen extends ConsumerStatefulWidget {" + [System.Environment]::NewLine
$sugg += "  const SuggestionBoxScreen({super.key});" + [System.Environment]::NewLine
$sugg += "  @override" + [System.Environment]::NewLine
$sugg += "  ConsumerState<SuggestionBoxScreen> createState() => _State();" + [System.Environment]::NewLine
$sugg += "}" + [System.Environment]::NewLine
$sugg += [System.Environment]::NewLine
$sugg += "class _State extends ConsumerState<SuggestionBoxScreen> {" + [System.Environment]::NewLine
$sugg += "  final _ctrl = TextEditingController();" + [System.Environment]::NewLine
$sugg += "  bool _anon = true, _sending = false;" + [System.Environment]::NewLine
$sugg += "  @override" + [System.Environment]::NewLine
$sugg += "  void dispose() { _ctrl.dispose(); super.dispose(); }" + [System.Environment]::NewLine
$sugg += [System.Environment]::NewLine
$sugg += "  Future<void> _submit() async {" + [System.Environment]::NewLine
$sugg += "    if (_ctrl.text.trim().isEmpty) return;" + [System.Environment]::NewLine
$sugg += "    setState(() => _sending = true);" + [System.Environment]::NewLine
$sugg += "    final user = ref.read(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$sugg += "    final s = SuggestionModel(id: const Uuid().v4(), content: _ctrl.text.trim(), userId: _anon ? null : user?.uid, createdAt: DateTime.now());" + [System.Environment]::NewLine
$sugg += "    await FirebaseFirestore.instance.collection('suggestions').doc(s.id).set(s.toFirestore());" + [System.Environment]::NewLine
$sugg += "    _ctrl.clear();" + [System.Environment]::NewLine
$sugg += "    setState(() => _sending = false);" + [System.Environment]::NewLine
$sugg += "    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suggestion submitted! Thank you.')));" + [System.Environment]::NewLine
$sugg += "  }" + [System.Environment]::NewLine
$sugg += [System.Environment]::NewLine
$sugg += "  @override" + [System.Environment]::NewLine
$sugg += "  Widget build(BuildContext context) {" + [System.Environment]::NewLine
$sugg += "    final user = ref.watch(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$sugg += "    final async = ref.watch(suggestionsProvider);" + [System.Environment]::NewLine
$sugg += "    return Scaffold(" + [System.Environment]::NewLine
$sugg += "      appBar: AppBar(title: const Text('Suggestion Box'))," + [System.Environment]::NewLine
$sugg += "      body: Column(children: [" + [System.Environment]::NewLine
$sugg += "        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16)," + [System.Environment]::NewLine
$sugg += "            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider.withOpacity(0.5)))," + [System.Environment]::NewLine
$sugg += "            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [" + [System.Environment]::NewLine
$sugg += "              const Row(children: [Icon(Icons.lightbulb_outline, color: AppColors.warning), SizedBox(width: 8), Expanded(child: Text('Share ideas with leadership', style: TextStyle(fontWeight: FontWeight.w600)))])," + [System.Environment]::NewLine
$sugg += "              const SizedBox(height: 12)," + [System.Environment]::NewLine
$sugg += "              TextField(controller: _ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Type your suggestion here...', alignLabelWithHint: true))," + [System.Environment]::NewLine
$sugg += "              const SizedBox(height: 8)," + [System.Environment]::NewLine
$sugg += "              Row(children: [Switch(value: _anon, onChanged: (v) => setState(() => _anon = v)), const Text('Submit anonymously')])," + [System.Environment]::NewLine
$sugg += "              ElevatedButton(onPressed: _sending ? null : _submit, child: _sending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Suggestion'))," + [System.Environment]::NewLine
$sugg += "            ]))," + [System.Environment]::NewLine
$sugg += "        if (user?.isAdmin == true)" + [System.Environment]::NewLine
$sugg += "          Expanded(child: async.when(" + [System.Environment]::NewLine
$sugg += "            loading: () => const Center(child: CircularProgressIndicator())," + [System.Environment]::NewLine
$sugg += "            error: (e, _) => Center(child: Text(e.toString()))," + [System.Environment]::NewLine
$sugg += "            data: (list) => list.isEmpty" + [System.Environment]::NewLine
$sugg += "                ? const Center(child: Text('No suggestions yet.'))" + [System.Environment]::NewLine
$sugg += "                : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: list.length," + [System.Environment]::NewLine
$sugg += "                    itemBuilder: (_, i) => Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [" + [System.Environment]::NewLine
$sugg += "                      Row(children: [" + [System.Environment]::NewLine
$sugg += "                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20))," + [System.Environment]::NewLine
$sugg += "                            child: Text(list[i].userId == null ? 'Anonymous' : 'Member', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)))," + [System.Environment]::NewLine
$sugg += "                        const Spacer()," + [System.Environment]::NewLine
$sugg += "                        Text(DateFormat('d MMM y').format(list[i].createdAt), style: Theme.of(context).textTheme.bodySmall)," + [System.Environment]::NewLine
$sugg += "                        if (!list[i].isRead) Container(margin: const EdgeInsets.only(left: 6), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))," + [System.Environment]::NewLine
$sugg += "                      ])," + [System.Environment]::NewLine
$sugg += "                      const SizedBox(height: 8)," + [System.Environment]::NewLine
$sugg += "                      Text(list[i].content, style: Theme.of(context).textTheme.bodyMedium)," + [System.Environment]::NewLine
$sugg += "                      if (!list[i].isRead) TextButton(onPressed: () => FirebaseFirestore.instance.collection('suggestions').doc(list[i].id).update({'isRead': true}), child: const Text('Mark as read'))," + [System.Environment]::NewLine
$sugg += "                    ]))))" + [System.Environment]::NewLine
$sugg += "          ))" + [System.Environment]::NewLine
$sugg += "        else" + [System.Environment]::NewLine
$sugg += "          Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [" + [System.Environment]::NewLine
$sugg += "            const Icon(Icons.lock_outline, size: 48, color: AppColors.textHint)," + [System.Environment]::NewLine
$sugg += "            const SizedBox(height: 12)," + [System.Environment]::NewLine
$sugg += "            Text('Your suggestion goes directly to leadership.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)," + [System.Environment]::NewLine
$sugg += "            Text('All suggestions are confidential.', style: Theme.of(context).textTheme.bodySmall)," + [System.Environment]::NewLine
$sugg += "          ])))," + [System.Environment]::NewLine
$sugg += "      ])," + [System.Environment]::NewLine
$sugg += "    );" + [System.Environment]::NewLine
$sugg += "  }" + [System.Environment]::NewLine
$sugg += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\features\suggestions\suggestion_box_screen.dart", $sugg, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: suggestion_box_screen.dart" -ForegroundColor Cyan

# ── shoutouts_screen.dart ─────────────────────────────────────────────────────
$shout = "import 'package:flutter/material.dart';" + [System.Environment]::NewLine
$shout += "import 'package:flutter_riverpod/flutter_riverpod.dart';" + [System.Environment]::NewLine
$shout += "import 'package:cloud_firestore/cloud_firestore.dart';" + [System.Environment]::NewLine
$shout += "import 'package:intl/intl.dart';" + [System.Environment]::NewLine
$shout += "import 'package:uuid/uuid.dart';" + [System.Environment]::NewLine
$shout += "import '../../shared/theme/app_theme.dart';" + [System.Environment]::NewLine
$shout += "import '../../shared/widgets/safe_avatar.dart';" + [System.Environment]::NewLine
$shout += "import '../../providers/providers.dart';" + [System.Environment]::NewLine
$shout += "import '../../models/phase2_models.dart';" + [System.Environment]::NewLine
$shout += "import '../../models/user_model.dart';" + [System.Environment]::NewLine
$shout += [System.Environment]::NewLine
$shout += "final shoutoutsProvider = StreamProvider<List<ShoutoutModel>>((ref) {" + [System.Environment]::NewLine
$shout += "  return FirebaseFirestore.instance.collection('shoutouts').orderBy('createdAt', descending: true).limit(30).snapshots().map((s) => s.docs.map(ShoutoutModel.fromFirestore).toList());" + [System.Environment]::NewLine
$shout += "});" + [System.Environment]::NewLine
$shout += [System.Environment]::NewLine
$shout += "class ShoutoutsScreen extends ConsumerWidget {" + [System.Environment]::NewLine
$shout += "  const ShoutoutsScreen({super.key});" + [System.Environment]::NewLine
$shout += "  @override" + [System.Environment]::NewLine
$shout += "  Widget build(BuildContext context, WidgetRef ref) {" + [System.Environment]::NewLine
$shout += "    final async = ref.watch(shoutoutsProvider);" + [System.Environment]::NewLine
$shout += "    final user = ref.watch(currentUserProvider).valueOrNull;" + [System.Environment]::NewLine
$shout += "    return Scaffold(" + [System.Environment]::NewLine
$shout += "      appBar: AppBar(title: const Text('Shoutouts Wall'))," + [System.Environment]::NewLine
$shout += "      body: async.when(" + [System.Environment]::NewLine
$shout += "        loading: () => const Center(child: CircularProgressIndicator())," + [System.Environment]::NewLine
$shout += "        error: (e, _) => Center(child: Text(e.toString()))," + [System.Environment]::NewLine
$shout += "        data: (list) => list.isEmpty" + [System.Environment]::NewLine
$shout += "            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [" + [System.Environment]::NewLine
$shout += "                const Icon(Icons.celebration, size: 80, color: AppColors.textHint)," + [System.Environment]::NewLine
$shout += "                const SizedBox(height: 16)," + [System.Environment]::NewLine
$shout += "                Text('No shoutouts yet', style: Theme.of(context).textTheme.headlineSmall)," + [System.Environment]::NewLine
$shout += "                const SizedBox(height: 8)," + [System.Environment]::NewLine
$shout += "                Text('Appreciate a fellow choir member!', style: Theme.of(context).textTheme.bodyMedium)," + [System.Environment]::NewLine
$shout += "              ]))" + [System.Environment]::NewLine
$shout += "            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length," + [System.Environment]::NewLine
$shout += "                itemBuilder: (_, i) => _ShoutoutCard(shoutout: list[i], currentUserId: user?.uid ?? '')))," + [System.Environment]::NewLine
$shout += "      floatingActionButton: FloatingActionButton.extended(" + [System.Environment]::NewLine
$shout += "        onPressed: () => _showDialog(context, ref, user)," + [System.Environment]::NewLine
$shout += "        icon: const Icon(Icons.favorite), label: const Text('Give Shoutout')," + [System.Environment]::NewLine
$shout += "        backgroundColor: Colors.pink)," + [System.Environment]::NewLine
$shout += "    );" + [System.Environment]::NewLine
$shout += "  }" + [System.Environment]::NewLine
$shout += [System.Environment]::NewLine
$shout += "  void _showDialog(BuildContext ctx, WidgetRef ref, user) {" + [System.Environment]::NewLine
$shout += "    if (user == null) return;" + [System.Environment]::NewLine
$shout += "    UserModel? selected;" + [System.Environment]::NewLine
$shout += "    final msgCtrl = TextEditingController();" + [System.Environment]::NewLine
$shout += "    showModalBottomSheet(context: ctx, isScrollControlled: true," + [System.Environment]::NewLine
$shout += "        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))," + [System.Environment]::NewLine
$shout += "        builder: (c) => StatefulBuilder(builder: (c, set) => Padding(" + [System.Environment]::NewLine
$shout += "          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24)," + [System.Environment]::NewLine
$shout += "          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [" + [System.Environment]::NewLine
$shout += "            Text('Give a Shoutout', style: Theme.of(ctx).textTheme.headlineSmall)," + [System.Environment]::NewLine
$shout += "            const SizedBox(height: 16)," + [System.Environment]::NewLine
$shout += "            ref.watch(allMembersProvider).when(" + [System.Environment]::NewLine
$shout += "              loading: () => const CircularProgressIndicator(), error: (_, __) => const SizedBox()," + [System.Environment]::NewLine
$shout += "              data: (members) => DropdownButtonFormField<UserModel>(" + [System.Environment]::NewLine
$shout += "                value: selected," + [System.Environment]::NewLine
$shout += "                decoration: const InputDecoration(labelText: 'Who are you appreciating?')," + [System.Environment]::NewLine
$shout += "                items: members.where((m) => m.uid != user.uid).map((m) => DropdownMenuItem(value: m, child: Text(m.name + ' (' + m.voicePart + ')'))).toList()," + [System.Environment]::NewLine
$shout += "                onChanged: (v) => set(() => selected = v)," + [System.Environment]::NewLine
$shout += "              )," + [System.Environment]::NewLine
$shout += "            )," + [System.Environment]::NewLine
$shout += "            const SizedBox(height: 12)," + [System.Environment]::NewLine
$shout += "            TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Your message', alignLabelWithHint: true))," + [System.Environment]::NewLine
$shout += "            const SizedBox(height: 16)," + [System.Environment]::NewLine
$shout += "            ElevatedButton(" + [System.Environment]::NewLine
$shout += "              onPressed: () async {" + [System.Environment]::NewLine
$shout += "                if (selected == null || msgCtrl.text.isEmpty) return;" + [System.Environment]::NewLine
$shout += "                final s = ShoutoutModel(id: const Uuid().v4(), fromUserId: user.uid, fromName: user.name, toUserId: selected!.uid, toName: selected!.name, message: msgCtrl.text.trim(), fromVoicePart: user.voicePart, toVoicePart: selected!.voicePart, createdAt: DateTime.now());" + [System.Environment]::NewLine
$shout += "                await FirebaseFirestore.instance.collection('shoutouts').doc(s.id).set(s.toFirestore());" + [System.Environment]::NewLine
$shout += "                if (c.mounted) Navigator.pop(c);" + [System.Environment]::NewLine
$shout += "              }," + [System.Environment]::NewLine
$shout += "              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink)," + [System.Environment]::NewLine
$shout += "              child: const Text('Send Shoutout')," + [System.Environment]::NewLine
$shout += "            )," + [System.Environment]::NewLine
$shout += "          ])," + [System.Environment]::NewLine
$shout += "        )));" + [System.Environment]::NewLine
$shout += "  }" + [System.Environment]::NewLine
$shout += "}" + [System.Environment]::NewLine
$shout += [System.Environment]::NewLine
$shout += "class _ShoutoutCard extends StatelessWidget {" + [System.Environment]::NewLine
$shout += "  final ShoutoutModel shoutout; final String currentUserId;" + [System.Environment]::NewLine
$shout += "  const _ShoutoutCard({required this.shoutout, required this.currentUserId});" + [System.Environment]::NewLine
$shout += "  @override" + [System.Environment]::NewLine
$shout += "  Widget build(BuildContext context) {" + [System.Environment]::NewLine
$shout += "    final hasLiked = shoutout.likes.contains(currentUserId);" + [System.Environment]::NewLine
$shout += "    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [" + [System.Environment]::NewLine
$shout += "      Row(children: [" + [System.Environment]::NewLine
$shout += "        SafeAvatar(photoUrl: null, name: shoutout.fromName, voicePart: shoutout.fromVoicePart ?? '', radius: 18)," + [System.Environment]::NewLine
$shout += "        const SizedBox(width: 8)," + [System.Environment]::NewLine
$shout += "        Text(shoutout.fromName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))," + [System.Environment]::NewLine
$shout += "        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: Colors.pink))," + [System.Environment]::NewLine
$shout += "        SafeAvatar(photoUrl: null, name: shoutout.toName, voicePart: shoutout.toVoicePart ?? '', radius: 18)," + [System.Environment]::NewLine
$shout += "        const SizedBox(width: 8)," + [System.Environment]::NewLine
$shout += "        Expanded(child: Text(shoutout.toName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))," + [System.Environment]::NewLine
$shout += "        Text(DateFormat('d MMM').format(shoutout.createdAt), style: Theme.of(context).textTheme.bodySmall)," + [System.Environment]::NewLine
$shout += "      ])," + [System.Environment]::NewLine
$shout += "      const SizedBox(height: 10)," + [System.Environment]::NewLine
$shout += "      Container(padding: const EdgeInsets.all(12)," + [System.Environment]::NewLine
$shout += "          decoration: BoxDecoration(color: Colors.pink.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.pink.withOpacity(0.2)))," + [System.Environment]::NewLine
$shout += "          child: Text(shoutout.message, style: Theme.of(context).textTheme.bodyMedium))," + [System.Environment]::NewLine
$shout += "      const SizedBox(height: 8)," + [System.Environment]::NewLine
$shout += "      GestureDetector(" + [System.Environment]::NewLine
$shout += "        onTap: () async {" + [System.Environment]::NewLine
$shout += "          final r = FirebaseFirestore.instance.collection('shoutouts').doc(shoutout.id);" + [System.Environment]::NewLine
$shout += "          if (hasLiked) { await r.update({'likes': FieldValue.arrayRemove([currentUserId])}); }" + [System.Environment]::NewLine
$shout += "          else { await r.update({'likes': FieldValue.arrayUnion([currentUserId])}); }" + [System.Environment]::NewLine
$shout += "        }," + [System.Environment]::NewLine
$shout += "        child: Row(children: [" + [System.Environment]::NewLine
$shout += "          Icon(hasLiked ? Icons.favorite : Icons.favorite_border, color: hasLiked ? Colors.red : AppColors.textHint, size: 18)," + [System.Environment]::NewLine
$shout += "          const SizedBox(width: 4)," + [System.Environment]::NewLine
$shout += "          Text(shoutout.likes.length.toString(), style: TextStyle(color: hasLiked ? Colors.red : AppColors.textHint, fontSize: 13))," + [System.Environment]::NewLine
$shout += "        ])," + [System.Environment]::NewLine
$shout += "      )," + [System.Environment]::NewLine
$shout += "    ])));" + [System.Environment]::NewLine
$shout += "  }" + [System.Environment]::NewLine
$shout += "}" + [System.Environment]::NewLine

[System.IO.File]::WriteAllText("lib\features\shoutouts\shoutouts_screen.dart", $shout, [System.Text.Encoding]::UTF8)
Write-Host "  fixed: shoutouts_screen.dart" -ForegroundColor Cyan

Write-Host ""
Write-Host "All Phase 2 & 3 files fixed!" -ForegroundColor Green
Write-Host "Press 'R' in Flutter terminal for full restart" -ForegroundColor Yellow
