# Build all remaining screens matching real Firestore structure

function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $path" -ForegroundColor Cyan
}

# ══════════════════════════════════════════════════════════════════════════════
# Fix models.dart to match real Firestore field names
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\models\models.dart" @'
import 'package:cloud_firestore/cloud_firestore.dart';

enum SongType { fullSong, vocalPart, stem, recording }

// ── Song ─────────────────────────────────────────────────────────────────────
class SongModel {
  final String id, title, addedBy, addedByName;
  final String? description, fullSongUrl, telegramLink, youtubeUrl, youtubeVideoId;
  final DateTime addedAt;
  final Map<String, dynamic> stems;

  const SongModel({
    required this.id, required this.title,
    required this.addedBy, required this.addedByName,
    this.description, this.fullSongUrl, this.telegramLink,
    this.youtubeUrl, this.youtubeVideoId,
    required this.addedAt, this.stems = const {},
  });

  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SongModel(
      id: doc.id,
      title: d['title'] ?? '',
      addedBy: d['addedBy'] ?? '',
      addedByName: d['addedByName'] ?? '',
      description: d['description'],
      fullSongUrl: d['fullSongUrl'],
      telegramLink: d['telegramLink'],
      youtubeUrl: d['youtubeUrl'],
      youtubeVideoId: d['youtubeVideoId'],
      addedAt: (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stems: Map<String, dynamic>.from(d['stems'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title, 'addedBy': addedBy, 'addedByName': addedByName,
    'description': description, 'fullSongUrl': fullSongUrl,
    'telegramLink': telegramLink, 'youtubeUrl': youtubeUrl,
    'youtubeVideoId': youtubeVideoId,
    'addedAt': Timestamp.fromDate(addedAt), 'stems': stems,
  };
}

// ── Session ───────────────────────────────────────────────────────────────────
class SessionModel {
  final String id, qrCode, createdBy;
  final String? label;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String> checkedInUids;

  const SessionModel({
    required this.id, required this.qrCode, required this.createdBy,
    this.label, required this.createdAt, this.expiresAt,
    required this.isActive, this.checkedInUids = const [],
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id, qrCode: d['qrCode'] ?? '', createdBy: d['createdBy'] ?? '',
      label: d['label'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      isActive: d['isActive'] ?? false,
      checkedInUids: List<String>.from(d['checkedInUids'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'qrCode': qrCode, 'createdBy': createdBy, 'label': label,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'isActive': isActive, 'checkedInUids': checkedInUids,
  };
}

// ── Attendance ────────────────────────────────────────────────────────────────
class AttendanceRecord {
  final String id, userId, fullName, dateStr;
  final String? sessionCode;
  final DateTime checkInTime;

  const AttendanceRecord({
    required this.id, required this.userId, required this.fullName,
    required this.dateStr, this.sessionCode, required this.checkInTime,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      userId: d['userId'] ?? d['uid'] ?? '',
      fullName: d['fullName'] ?? '',
      dateStr: d['dateStr'] ?? '',
      sessionCode: d['sessionCode'],
      checkInTime: (d['checkInTime'] as Timestamp?)?.toDate() ??
          (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId, 'fullName': fullName, 'dateStr': dateStr,
    'sessionCode': sessionCode, 'checkInTime': Timestamp.fromDate(checkInTime),
  };
}

// ── Quiet Time Post ───────────────────────────────────────────────────────────
class QuietTimePost {
  final String id, userId, fullName, verse, reflection;
  final String? voicePart;
  final bool isAnonymous;
  final DateTime timestamp;

  const QuietTimePost({
    required this.id, required this.userId, required this.fullName,
    required this.verse, required this.reflection,
    this.voicePart, this.isAnonymous = false, required this.timestamp,
  });

  // Keep backward compat
  String get userName => fullName;
  DateTime get date => timestamp;

  factory QuietTimePost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuietTimePost(
      id: doc.id,
      userId: d['userId'] ?? d['uid'] ?? '',
      fullName: d['fullName'] ?? d['userName'] ?? 'Anonymous',
      verse: d['verse'] ?? '',
      reflection: d['reflection'] ?? '',
      voicePart: d['voicePart'],
      isAnonymous: d['isAnonymous'] ?? false,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ??
          (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId, 'fullName': fullName, 'verse': verse,
    'reflection': reflection, 'voicePart': voicePart,
    'isAnonymous': isAnonymous, 'timestamp': Timestamp.fromDate(timestamp),
  };
}

// ── Devotional ────────────────────────────────────────────────────────────────
class DevotionalModel {
  final String id, verse, verseText, reflection, prayer;
  final DateTime date;

  const DevotionalModel({
    required this.id, required this.date, required this.verse,
    required this.verseText, required this.reflection, required this.prayer,
  });

  factory DevotionalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DevotionalModel(
      id: doc.id,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verse: d['verse'] ?? '', verseText: d['verseText'] ?? '',
      reflection: d['reflection'] ?? '', prayer: d['prayer'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'date': Timestamp.fromDate(date), 'verse': verse,
    'verseText': verseText, 'reflection': reflection, 'prayer': prayer,
  };
}

// ── Announcement ──────────────────────────────────────────────────────────────
class AnnouncementModel {
  final String id, title, message, createdBy;
  final DateTime createdAt;
  final List<String> readBy;

  const AnnouncementModel({
    required this.id, required this.title, required this.message,
    required this.createdBy, required this.createdAt, this.readBy = const [],
  });

  // backward compat
  String get body => message;
  DateTime get date => createdAt;

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: d['title'] ?? '',
      message: d['message'] ?? d['body'] ?? '',
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(d['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title, 'message': message, 'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt), 'readBy': readBy,
  };
}

// ── Rehearsal ─────────────────────────────────────────────────────────────────
class RehearsalModel {
  final String id, rehearsalId;
  final DateTime date;
  final List<String> attendees;
  final String? title, location, notes;

  const RehearsalModel({
    required this.id, required this.rehearsalId, required this.date,
    this.attendees = const [], this.title, this.location, this.notes,
  });

  factory RehearsalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RehearsalModel(
      id: doc.id,
      rehearsalId: d['rehearsalId'] ?? doc.id,
      date: (d['date'] as Timestamp?)?.toDate() ??
          (d['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attendees: List<String>.from(d['attendees'] ?? []),
      title: d['title'],
      location: d['location'],
      notes: d['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'rehearsalId': rehearsalId, 'date': Timestamp.fromDate(date),
    'attendees': attendees, 'title': title,
    'location': location, 'notes': notes,
  };
}

// ── YouTube Link ──────────────────────────────────────────────────────────────
class YouTubeLink {
  final String id, title, url, addedBy;
  final String? description;
  final DateTime addedAt;

  const YouTubeLink({
    required this.id, required this.title, required this.url,
    required this.addedBy, this.description, required this.addedAt,
  });

  factory YouTubeLink.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return YouTubeLink(
      id: doc.id, title: d['title'] ?? '', url: d['url'] ?? '',
      addedBy: d['addedBy'] ?? '', description: d['description'],
      addedAt: (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title, 'url': url, 'addedBy': addedBy,
    'description': description, 'addedAt': Timestamp.fromDate(addedAt),
  };
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Fix firestore_service.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\services\firestore_service.dart" @'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<UserModel>> streamAllMembers() => _db
    .collection('users').orderBy('fullName').snapshots()
    .map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Stream<List<UserModel>> streamPendingMembers() => _db
    .collection('users').where('isApproved', isEqualTo: false).snapshots()
    .map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Future<void> approveUser(String uid) =>
    _db.collection('users').doc(uid).update({'isApproved': true});

  Future<void> deleteUser(String uid) =>
    _db.collection('users').doc(uid).delete();

  Future<void> updateUserRole(String uid, UserRole role) =>
    _db.collection('users').doc(uid).update({
      'isAdmin': role == UserRole.admin,
      'role': role == UserRole.admin ? 'admin' : 'member',
    });

  Future<void> updateProfile({required String uid, String? name,
      String? phone, String? voicePart, String? photoUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['fullName'] = name;
    if (phone != null) updates['phoneNumber'] = phone;
    if (voicePart != null) { updates['voicePart'] = voicePart; updates['mainInstrument'] = voicePart; }
    if (photoUrl != null) updates['profilePhotoUrl'] = photoUrl;
    await _db.collection('users').doc(uid).update(updates);
  }

  Future<SessionModel> createSession({required String createdBy,
      String? label, Duration validity = const Duration(hours: 2)}) async {
    final id = _uuid.v4();
    final qrCode = _uuid.v4();
    final now = DateTime.now();
    final session = SessionModel(
      id: id, qrCode: qrCode, createdAt: now, expiresAt: now.add(validity),
      isActive: true, createdBy: createdBy,
      label: label ?? 'Rehearsal ${now.day}/${now.month}/${now.year}',
    );
    await _db.collection('sessions').doc(id).set(session.toFirestore());
    return session;
  }

  Future<void> endSession(String id) =>
    _db.collection('sessions').doc(id).update({'isActive': false});

  Stream<SessionModel?> streamActiveSession() => _db
    .collection('sessions').where('isActive', isEqualTo: true).limit(1).snapshots()
    .map((s) => s.docs.isEmpty ? null : SessionModel.fromFirestore(s.docs.first));

  Future<bool> checkIn({required String uid, required String qrCode,
      required String fullName}) async {
    final query = await _db.collection('sessions')
      .where('qrCode', isEqualTo: qrCode)
      .where('isActive', isEqualTo: true).limit(1).get();
    if (query.docs.isEmpty) return false;
    final sessionDoc = query.docs.first;
    final session = SessionModel.fromFirestore(sessionDoc);
    if (session.checkedInUids.contains(uid)) return true;
    if (session.expiresAt != null && DateTime.now().isAfter(session.expiresAt!)) return false;
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final batch = _db.batch();
    batch.update(sessionDoc.reference, {'checkedInUids': FieldValue.arrayUnion([uid])});
    final attRef = _db.collection('attendance').doc();
    batch.set(attRef, {
      'userId': uid, 'fullName': fullName, 'dateStr': dateStr,
      'sessionCode': session.qrCode, 'checkInTime': Timestamp.fromDate(now),
    });
    batch.update(_db.collection('users').doc(uid), {
      'attendanceCount': FieldValue.increment(1),
      'dailyStreak': FieldValue.increment(1),
    });
    await batch.commit();
    return true;
  }

  Stream<List<AttendanceRecord>> streamUserAttendance(String uid, {int days = 60}) {
    final since = DateTime.now().subtract(Duration(days: days));
    return _db.collection('attendance')
      .where('userId', isEqualTo: uid)
      .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .orderBy('checkInTime', descending: true).snapshots()
      .map((s) => s.docs.map(AttendanceRecord.fromFirestore).toList());
  }

  Stream<List<SongModel>> streamSongs() => _db
    .collection('songs').orderBy('title').snapshots()
    .map((s) => s.docs.map(SongModel.fromFirestore).toList());

  Future<void> addSong(SongModel song) =>
    _db.collection('songs').doc(song.id).set(song.toFirestore());

  Future<void> deleteSong(String id) =>
    _db.collection('songs').doc(id).delete();

  Stream<List<YouTubeLink>> streamYoutubeLinks() => _db
    .collection('youtube_links').orderBy('addedAt', descending: true).snapshots()
    .map((s) => s.docs.map(YouTubeLink.fromFirestore).toList());

  Future<void> postQuietTime(QuietTimePost post) =>
    _db.collection('quiet_time_posts').doc(post.id).set(post.toFirestore());

  Stream<List<QuietTimePost>> streamQuietTimePosts({int limit = 20}) => _db
    .collection('quiet_time_posts').orderBy('timestamp', descending: true).limit(limit).snapshots()
    .map((s) => s.docs.map(QuietTimePost.fromFirestore).toList());

  Stream<DevotionalModel?> streamTodayDevotional() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return _db.collection('devotionals')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end)).limit(1).snapshots()
      .map((s) => s.docs.isEmpty ? null : DevotionalModel.fromFirestore(s.docs.first));
  }

  Stream<List<AnnouncementModel>> streamAnnouncements({int limit = 10}) => _db
    .collection('announcements').orderBy('createdAt', descending: true).limit(limit).snapshots()
    .map((s) => s.docs.map(AnnouncementModel.fromFirestore).toList());

  Future<void> addAnnouncement(AnnouncementModel a) =>
    _db.collection('announcements').doc(a.id).set(a.toFirestore());

  Future<void> deleteAnnouncement(String id) =>
    _db.collection('announcements').doc(id).delete();

  Stream<List<RehearsalModel>> streamUpcomingRehearsals() => _db
    .collection('rehearsals')
    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
    .orderBy('date').snapshots()
    .map((s) => s.docs.map(RehearsalModel.fromFirestore).toList());

  Future<void> addRehearsal(RehearsalModel r) =>
    _db.collection('rehearsals').doc(r.id).set(r.toFirestore());

  Future<void> deleteRehearsal(String id) =>
    _db.collection('rehearsals').doc(id).delete();

  Future<Map<String, int>> getAdminStats() async {
    final users = await _db.collection('users').get();
    final pending = users.docs.where((d) => d.data()['isApproved'] == false).length;
    final complete = users.docs.where((d) {
      final data = d.data();
      return data['fullName'] != null && data['email'] != null && data['phoneNumber'] != null;
    }).length;
    final activeSessions = await _db.collection('sessions')
      .where('isActive', isEqualTo: true).count().get();
    return {
      'totalMembers': users.docs.length,
      'completeProfiles': complete,
      'pendingSetup': pending,
      'activeSessions': activeSessions.count ?? 0,
    };
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Fix providers.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\providers\providers.dart" @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/models.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final authStateProvider = StreamProvider<User?>((ref) =>
  ref.watch(authServiceProvider).authStateChanges);

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user == null ? Stream.value(null)
      : ref.watch(authServiceProvider).streamUserProfile(user.uid),
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final allMembersProvider = StreamProvider<List<UserModel>>((ref) =>
  ref.watch(firestoreServiceProvider).streamAllMembers());

final pendingMembersProvider = StreamProvider<List<UserModel>>((ref) =>
  ref.watch(firestoreServiceProvider).streamPendingMembers());

final songsProvider = StreamProvider<List<SongModel>>((ref) =>
  ref.watch(firestoreServiceProvider).streamSongs());

final youtubeLinkProvider = StreamProvider<List<YouTubeLink>>((ref) =>
  ref.watch(firestoreServiceProvider).streamYoutubeLinks());

final activeSessionProvider = StreamProvider<SessionModel?>((ref) =>
  ref.watch(firestoreServiceProvider).streamActiveSession());

final userAttendanceProvider = StreamProvider.family<List<AttendanceRecord>, String>((ref, uid) =>
  ref.watch(firestoreServiceProvider).streamUserAttendance(uid));

final quietTimePostsProvider = StreamProvider<List<QuietTimePost>>((ref) =>
  ref.watch(firestoreServiceProvider).streamQuietTimePosts());

final todayDevotionalProvider = StreamProvider<DevotionalModel?>((ref) =>
  ref.watch(firestoreServiceProvider).streamTodayDevotional());

final announcementsProvider = StreamProvider<List<AnnouncementModel>>((ref) =>
  ref.watch(firestoreServiceProvider).streamAnnouncements());

final upcomingRehearsalsProvider = StreamProvider<List<RehearsalModel>>((ref) =>
  ref.watch(firestoreServiceProvider).streamUpcomingRehearsals());

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) =>
  ref.watch(firestoreServiceProvider).getAdminStats());
'@

# ══════════════════════════════════════════════════════════════════════════════
# 2. Profile Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\profile\profile_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  String? _voicePart;
  bool _saving = false;

  static const _parts = ['SOPRANO','ALTO','TENOR','BASS','PIANO','DRUMS','GUITAR'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    await ref.read(firestoreServiceProvider).updateProfile(
      uid: uid,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      voicePart: _voicePart,
    );
    setState(() { _saving = false; _editing = false; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!')));
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox();
          if (!_editing) {
            _nameCtrl.text = user.name;
            _phoneCtrl.text = user.phone;
            _voicePart ??= user.voicePart;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Avatar
              Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: voicePartColor(user.voicePart).withOpacity(0.2),
                  backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                      ? NetworkImage(user.photoUrl!) : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
                              color: voicePartColor(user.voicePart)))
                      : null,
                ),
              ]),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: voicePartColor(user.voicePart).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(user.voicePart.toUpperCase(),
                    style: TextStyle(color: voicePartColor(user.voicePart),
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),

              if (_editing) ...[
                TextFormField(controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextFormField(controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _voicePart,
                  decoration: const InputDecoration(labelText: 'Voice / Instrument',
                      prefixIcon: Icon(Icons.music_note_outlined)),
                  items: _parts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _voicePart = v),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => setState(() => _editing = false),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(user.uid),
                    child: _saving
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save'),
                  )),
                ]),
              ] else ...[
                _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
                _InfoTile(icon: Icons.phone_outlined, label: 'Phone',
                    value: user.phone.isNotEmpty ? user.phone : 'Not set'),
                if (user.hostel != null && user.hostel!.isNotEmpty)
                  _InfoTile(icon: Icons.home_outlined, label: 'Hostel', value: user.hostel!),
                if (user.level != null && user.level!.isNotEmpty)
                  _InfoTile(icon: Icons.school_outlined, label: 'Level', value: user.level!),
                _InfoTile(icon: Icons.calendar_today_outlined, label: 'Joined',
                    value: DateFormat('dd/MM/yyyy').format(user.joinedAt)),
                _InfoTile(icon: Icons.check_circle_outline, label: 'Attendance',
                    value: user.attendanceCount.toString()),
                _InfoTile(icon: Icons.local_fire_department_outlined, label: 'Streak',
                    value: '${user.streak} days'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider.withOpacity(0.5)),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ]),
    ]),
  );
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# 3. Music Library Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\music\music_library_screen.dart" @'
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
        // ── Songs tab ──────────────────────────────────────────────────────
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

        // ── YouTube tab ────────────────────────────────────────────────────
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
'@

# ══════════════════════════════════════════════════════════════════════════════
# 4. Quiet Time Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\quiet_time\quiet_time_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/models.dart';

class QuietTimeScreen extends ConsumerWidget {
  const QuietTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(quietTimePostsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiet Time')),
      body: Column(children: [
        // Post button
        if (user != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showPostDialog(context, ref, user),
              icon: const Icon(Icons.add),
              label: const Text('Share Today\'s Quiet Time'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            ),
          ),

        Expanded(child: postsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (posts) => posts.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book, size: 64, color: AppColors.textHint),
                    SizedBox(height: 16),
                    Text('No quiet time posts yet.\nBe the first to share!',
                        textAlign: TextAlign.center),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: posts.length,
                  itemBuilder: (_, i) => _QtCard(post: posts[i])),
        )),
      ]),
    );
  }

  void _showPostDialog(BuildContext context, WidgetRef ref, user) {
    final verseCtrl = TextEditingController();
    final reflectionCtrl = TextEditingController();
    bool isAnonymous = false;

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
            Text('Share Quiet Time', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: verseCtrl,
                decoration: const InputDecoration(labelText: 'Bible Verse (e.g. John 3:16)',
                    prefixIcon: Icon(Icons.bookmark_outline))),
            const SizedBox(height: 12),
            TextField(controller: reflectionCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Your Reflection',
                    prefixIcon: Icon(Icons.edit_note), alignLabelWithHint: true)),
            const SizedBox(height: 8),
            Row(children: [
              Switch(value: isAnonymous,
                  onChanged: (v) => setModalState(() => isAnonymous = v)),
              const Text('Post anonymously'),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (verseCtrl.text.isEmpty || reflectionCtrl.text.isEmpty) return;
                final post = QuietTimePost(
                  id: const Uuid().v4(),
                  userId: user.uid,
                  fullName: isAnonymous ? 'Anonymous' : user.name,
                  verse: verseCtrl.text.trim(),
                  reflection: reflectionCtrl.text.trim(),
                  voicePart: user.voicePart,
                  isAnonymous: isAnonymous,
                  timestamp: DateTime.now(),
                );
                await ref.read(firestoreServiceProvider).postQuietTime(post);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Post'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QtCard extends StatelessWidget {
  final QuietTimePost post;
  const _QtCard({required this.post});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: voicePartColor(post.voicePart ?? '').withOpacity(0.2),
            child: Text(post.fullName[0].toUpperCase(),
                style: TextStyle(color: voicePartColor(post.voicePart ?? ''),
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.isAnonymous ? 'Anonymous' : post.fullName,
                style: Theme.of(context).textTheme.titleMedium),
            if (post.voicePart != null && post.voicePart!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: voicePartColor(post.voicePart!).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(post.voicePart!.toUpperCase(),
                    style: TextStyle(color: voicePartColor(post.voicePart!),
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ),
          ])),
          Text(DateFormat('MMM d').format(post.timestamp),
              style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.bookmark, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Text(post.verse, style: const TextStyle(
                fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 8),
        Text(post.reflection, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    ),
  );
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# 5. Attendance History Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\attendance\attendance_history_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final attendanceAsync = ref.watch(userAttendanceProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance History')),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user.name}', style: Theme.of(context).textTheme.titleLarge),
            Text('Your attendance for the last 60 days',
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
        Expanded(child: attendanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (records) {
            final presentDates = records.map((r) => r.dateStr).toSet();
            final days = List.generate(60, (i) {
              final d = DateTime.now().subtract(Duration(days: i));
              return d;
            });
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final day = days[i];
                final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
                final present = presentDates.contains(key);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                  ),
                  child: Row(children: [
                    Icon(present ? Icons.check_circle : Icons.cancel,
                        color: present ? AppColors.success : AppColors.error, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(DateFormat('EEEE, MMMM d, y').format(day),
                        style: Theme.of(context).textTheme.bodyLarge)),
                    Text(present ? 'Present' : 'Absent',
                        style: TextStyle(
                            color: present ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                );
              },
            );
          },
        )),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _downloadPdf(ref, user),
            icon: const Icon(Icons.download),
            label: const Text('Download Attendance PDF'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ),
      ]),
    );
  }

  Future<void> _downloadPdf(WidgetRef ref, user) async {
    final records = ref.read(userAttendanceProvider(user.uid)).valueOrNull ?? [];
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Asempa Choir — Attendance Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Member: ${user.name}  |  Part: ${user.voicePart}'),
        pw.Text('Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Date', 'Status'],
          data: records.map((r) => [
            DateFormat('EEE, dd MMM yyyy').format(r.checkInTime),
            'Present',
          ]).toList(),
        ),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# 6. Directory Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\directory\directory_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
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
'@

# ══════════════════════════════════════════════════════════════════════════════
# 7. Announcements Screen
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\features\announcements\announcements_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../models/models.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No announcements yet.'),
                ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) => _AnnouncementCard(
                    item: items[i], isAdmin: user?.isAdmin ?? false, ref: ref),
              ),
      ),
      floatingActionButton: user?.isAdmin == true
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context, ref, user!),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, user) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('New Announcement', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: msgCtrl, maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Message', alignLabelWithHint: true)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || msgCtrl.text.isEmpty) return;
              final a = AnnouncementModel(
                id: const Uuid().v4(),
                title: titleCtrl.text.trim(),
                message: msgCtrl.text.trim(),
                createdBy: user.uid,
                createdAt: DateTime.now(),
              );
              await ref.read(firestoreServiceProvider).addAnnouncement(a);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Post Announcement'),
          ),
        ]),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel item;
  final bool isAdmin;
  final WidgetRef ref;
  const _AnnouncementCard({required this.item, required this.isAdmin, required this.ref});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            Text(DateFormat('d MMM y • h:mm a').format(item.createdAt),
                style: Theme.of(context).textTheme.bodySmall),
          ])),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => ref.read(firestoreServiceProvider)
                  .deleteAnnouncement(item.id),
            ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(item.message, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    ),
  );
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Also fix auth_service.dart to use fullName field
# ══════════════════════════════════════════════════════════════════════════════
Write-File "lib\services\auth_service.dart" @'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel> register({required String name, required String email,
      required String password, required String phone, required String voicePart}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final now = DateTime.now();
    final data = {
      'fullName': name, 'email': email, 'phoneNumber': phone,
      'voicePart': voicePart, 'mainInstrument': voicePart,
      'isAdmin': false, 'role': 'member',
      'isApproved': false, 'isActive': true,
      'attendanceCount': 0, 'dailyStreak': 0,
      'joinedDate': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'instruments': [voicePart],
      'memberType': 'vocalist',
      'userId': cred.user!.uid,
    };
    await _db.collection('users').doc(cred.user!.uid).set(data);
    await cred.user!.updateDisplayName(name);
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _db.collection('users').doc(cred.user!.uid).update({
      'lastAccessDate': FieldValue.serverTimestamp(),
    });
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();

  Stream<UserModel?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Add url_launcher to pubspec
# ══════════════════════════════════════════════════════════════════════════════
Write-File "pubspec.yaml" @'
name: asempa_choir
description: Asempa Choir App - NUPS-G UMaT
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0
  flutter_riverpod: ^2.4.10
  go_router: ^13.2.0
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.7
  pdf: ^3.10.8
  printing: ^5.12.0
  path_provider: ^2.1.2
  just_audio: ^0.9.36
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  intl: ^0.19.0
  uuid: ^4.3.3
  image_picker: ^1.0.7
  permission_handler: ^11.3.0
  share_plus: ^7.2.2
  url_launcher: ^6.2.5
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
'@

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " All 6 screens built successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Now run:" -ForegroundColor Cyan
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  Then press 'r' in Flutter terminal to reload" -ForegroundColor White
