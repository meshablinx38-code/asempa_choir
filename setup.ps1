# Asempa Choir - Full Project Setup Script
# Run this from inside your asempa_choir folder
# PS C:\Users\user\Desktop\ASEMPA APP\asempa_choir> .\setup.ps1

$base = "lib"

# ── Create all directories ─────────────────────────────────────────────────
$dirs = @(
    "$base\models",
    "$base\services",
    "$base\providers",
    "$base\router",
    "$base\shared\theme",
    "$base\shared\widgets",
    "$base\features\auth",
    "$base\features\home",
    "$base\features\schedule",
    "$base\features\admin",
    "$base\features\checkin",
    "$base\features\attendance",
    "$base\features\music",
    "$base\features\quiet_time",
    "$base\features\profile",
    "$base\features\directory",
    "$base\features\announcements",
    "assets\images",
    "assets\icons",
    "assets\animations",
    "assets\fonts"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
Write-Host "Folders created" -ForegroundColor Green

# ── Helper function to write files ─────────────────────────────────────────
function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $path" -ForegroundColor Cyan
}

# ══════════════════════════════════════════════════════════════════════════════
# pubspec.yaml
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
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.2
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

# ══════════════════════════════════════════════════════════════════════════════
# lib/main.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\main.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'router/router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: AsempaChoirApp()));
}

class AsempaChoirApp extends ConsumerWidget {
  const AsempaChoirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Asempa Choir',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/shared/theme/app_theme.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\shared\theme\app_theme.dart" @'
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0D1B2A);
  static const primaryLight = Color(0xFF1A2E45);
  static const accent = Color(0xFF2196F3);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);
  static const surface = Color(0xFFF8F9FA);
  static const cardBg = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const adminBlue = Color(0xFF2196F3);
  static const adminGreen = Color(0xFF4CAF50);
  static const adminOrange = Color(0xFFFF9800);
  static const adminPurple = Color(0xFF9C27B0);
}

Color voicePartColor(String part) {
  switch (part.toUpperCase()) {
    case 'SOPRANO': return const Color(0xFFE91E63);
    case 'ALTO':    return const Color(0xFF9C27B0);
    case 'TENOR':   return const Color(0xFF2196F3);
    case 'BASS':    return const Color(0xFF4CAF50);
    case 'PIANO':   return const Color(0xFF607D8B);
    case 'DRUMS':   return const Color(0xFFFF5722);
    case 'GUITAR':  return const Color(0xFF795548);
    default:        return const Color(0xFF2196F3);
  }
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
        .copyWith(primary: AppColors.primary, secondary: AppColors.accent),
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/models/user_model.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\models\user_model.dart" @'
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { member, admin }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String voicePart;
  final UserRole role;
  final String? photoUrl;
  final DateTime joinedAt;
  final DateTime? lastLoginAt;
  final bool isApproved;
  final int attendanceCount;
  final int streak;

  const UserModel({
    required this.uid, required this.name, required this.email,
    required this.phone, required this.voicePart, required this.role,
    this.photoUrl, required this.joinedAt, this.lastLoginAt,
    required this.isApproved, this.attendanceCount = 0, this.streak = 0,
  });

  bool get isAdmin => role == UserRole.admin;
  String get firstName => name.split(' ').first;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, name: d['name'] ?? '', email: d['email'] ?? '',
      phone: d['phone'] ?? '', voicePart: d['voicePart'] ?? 'SOPRANO',
      role: d['role'] == 'admin' ? UserRole.admin : UserRole.member,
      photoUrl: d['photoUrl'],
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (d['lastLoginAt'] as Timestamp?)?.toDate(),
      isApproved: d['isApproved'] ?? false,
      attendanceCount: d['attendanceCount'] ?? 0,
      streak: d['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name, 'email': email, 'phone': phone, 'voicePart': voicePart,
    'role': role == UserRole.admin ? 'admin' : 'member', 'photoUrl': photoUrl,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    'isApproved': isApproved, 'attendanceCount': attendanceCount, 'streak': streak,
  };

  UserModel copyWith({String? name, String? phone, String? voicePart,
      String? photoUrl, bool? isApproved, int? attendanceCount, int? streak}) {
    return UserModel(
      uid: uid, name: name ?? this.name, email: email,
      phone: phone ?? this.phone, voicePart: voicePart ?? this.voicePart,
      role: role, photoUrl: photoUrl ?? this.photoUrl, joinedAt: joinedAt,
      lastLoginAt: lastLoginAt, isApproved: isApproved ?? this.isApproved,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      streak: streak ?? this.streak,
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/models/models.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\models\models.dart" @'
import 'package:cloud_firestore/cloud_firestore.dart';

enum SongType { fullSong, vocalPart, stem, recording }

class SongModel {
  final String id, title, uploadedBy;
  final String? artist, audioUrl, voicePart;
  final SongType type;
  final DateTime uploadedAt;
  const SongModel({required this.id, required this.title, required this.uploadedBy,
    this.artist, this.audioUrl, this.voicePart,
    required this.type, required this.uploadedAt});
  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SongModel(id: doc.id, title: d['title'] ?? '', uploadedBy: d['uploadedBy'] ?? '',
      artist: d['artist'], audioUrl: d['audioUrl'], voicePart: d['voicePart'],
      type: SongType.values.firstWhere((e) => e.name == (d['type'] ?? 'fullSong'), orElse: () => SongType.fullSong),
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now());
  }
  Map<String, dynamic> toFirestore() => {'title': title, 'artist': artist, 'type': type.name,
    'audioUrl': audioUrl, 'voicePart': voicePart, 'uploadedAt': Timestamp.fromDate(uploadedAt), 'uploadedBy': uploadedBy};
}

class SessionModel {
  final String id, qrCode, createdBy;
  final String? label;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String> checkedInUids;
  const SessionModel({required this.id, required this.qrCode, required this.createdBy,
    this.label, required this.createdAt, this.expiresAt,
    required this.isActive, this.checkedInUids = const []});
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionModel(id: doc.id, qrCode: d['qrCode'] ?? '', createdBy: d['createdBy'] ?? '',
      label: d['label'], createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      isActive: d['isActive'] ?? false, checkedInUids: List<String>.from(d['checkedInUids'] ?? []));
  }
  Map<String, dynamic> toFirestore() => {'qrCode': qrCode, 'createdBy': createdBy, 'label': label,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'isActive': isActive, 'checkedInUids': checkedInUids};
}

class AttendanceRecord {
  final String id, uid, sessionId;
  final DateTime date;
  final bool present;
  const AttendanceRecord({required this.id, required this.uid,
    required this.sessionId, required this.date, required this.present});
  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(id: doc.id, uid: d['uid'] ?? '', sessionId: d['sessionId'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(), present: d['present'] ?? false);
  }
  Map<String, dynamic> toFirestore() => {'uid': uid, 'sessionId': sessionId,
    'date': Timestamp.fromDate(date), 'present': present};
}

class QuietTimePost {
  final String id, uid, userName, voicePart, verse, reflection;
  final DateTime date;
  const QuietTimePost({required this.id, required this.uid, required this.userName,
    required this.voicePart, required this.verse, required this.reflection, required this.date});
  factory QuietTimePost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuietTimePost(id: doc.id, uid: d['uid'] ?? '', userName: d['userName'] ?? '',
      voicePart: d['voicePart'] ?? '', verse: d['verse'] ?? '',
      reflection: d['reflection'] ?? '', date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now());
  }
  Map<String, dynamic> toFirestore() => {'uid': uid, 'userName': userName, 'voicePart': voicePart,
    'verse': verse, 'reflection': reflection, 'date': Timestamp.fromDate(date)};
}

class DevotionalModel {
  final String id, verse, verseText, reflection, prayer;
  final DateTime date;
  const DevotionalModel({required this.id, required this.date, required this.verse,
    required this.verseText, required this.reflection, required this.prayer});
  factory DevotionalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DevotionalModel(id: doc.id, date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verse: d['verse'] ?? '', verseText: d['verseText'] ?? '',
      reflection: d['reflection'] ?? '', prayer: d['prayer'] ?? '');
  }
  Map<String, dynamic> toFirestore() => {'date': Timestamp.fromDate(date), 'verse': verse,
    'verseText': verseText, 'reflection': reflection, 'prayer': prayer};
}

class AnnouncementModel {
  final String id, title, body, createdBy;
  final DateTime date;
  const AnnouncementModel({required this.id, required this.title,
    required this.body, required this.date, required this.createdBy});
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(id: doc.id, title: d['title'] ?? '', body: d['body'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(), createdBy: d['createdBy'] ?? '');
  }
  Map<String, dynamic> toFirestore() => {'title': title, 'body': body,
    'date': Timestamp.fromDate(date), 'createdBy': createdBy};
}

class RehearsalModel {
  final String id, title, createdBy;
  final String? location, notes;
  final DateTime dateTime;
  const RehearsalModel({required this.id, required this.title, required this.dateTime,
    this.location, this.notes, required this.createdBy});
  factory RehearsalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RehearsalModel(id: doc.id, title: d['title'] ?? '',
      dateTime: (d['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'], notes: d['notes'], createdBy: d['createdBy'] ?? '');
  }
  Map<String, dynamic> toFirestore() => {'title': title, 'dateTime': Timestamp.fromDate(dateTime),
    'location': location, 'notes': notes, 'createdBy': createdBy};
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/services/auth_service.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\services\auth_service.dart" @'
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
    final user = UserModel(uid: cred.user!.uid, name: name, email: email, phone: phone,
      voicePart: voicePart, role: UserRole.member, joinedAt: DateTime.now(), isApproved: false);
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
    await cred.user!.updateDisplayName(name);
    return user;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _db.collection('users').doc(cred.user!.uid).update({'lastLoginAt': FieldValue.serverTimestamp()});
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

  Future<void> updateProfile({required String uid, String? name,
      String? phone, String? voicePart, String? photoUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (voicePart != null) updates['voicePart'] = voicePart;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    await _db.collection('users').doc(uid).update(updates);
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/services/firestore_service.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\services\firestore_service.dart" @'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<UserModel>> streamAllMembers() => _db.collection('users').orderBy('name')
    .snapshots().map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Stream<List<UserModel>> streamPendingMembers() => _db.collection('users')
    .where('isApproved', isEqualTo: false).snapshots()
    .map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Future<void> approveUser(String uid) =>
    _db.collection('users').doc(uid).update({'isApproved': true});

  Future<void> deleteUser(String uid) =>
    _db.collection('users').doc(uid).delete();

  Future<void> updateUserRole(String uid, UserRole role) =>
    _db.collection('users').doc(uid).update(
      {'role': role == UserRole.admin ? 'admin' : 'member'});

  Future<SessionModel> createSession({required String createdBy, String? label,
      Duration validity = const Duration(hours: 2)}) async {
    final id = _uuid.v4();
    final qrCode = _uuid.v4();
    final now = DateTime.now();
    final session = SessionModel(id: id, qrCode: qrCode, createdAt: now,
      expiresAt: now.add(validity), isActive: true, createdBy: createdBy,
      label: label ?? 'Rehearsal ${now.day}/${now.month}/${now.year}');
    await _db.collection('sessions').doc(id).set(session.toFirestore());
    return session;
  }

  Future<void> endSession(String sessionId) =>
    _db.collection('sessions').doc(sessionId).update({'isActive': false});

  Stream<SessionModel?> streamActiveSession() => _db.collection('sessions')
    .where('isActive', isEqualTo: true).limit(1).snapshots()
    .map((s) => s.docs.isEmpty ? null : SessionModel.fromFirestore(s.docs.first));

  Future<bool> checkIn({required String uid, required String qrCode}) async {
    final query = await _db.collection('sessions')
      .where('qrCode', isEqualTo: qrCode).where('isActive', isEqualTo: true).limit(1).get();
    if (query.docs.isEmpty) return false;
    final sessionDoc = query.docs.first;
    final session = SessionModel.fromFirestore(sessionDoc);
    if (session.checkedInUids.contains(uid)) return true;
    if (session.expiresAt != null && DateTime.now().isAfter(session.expiresAt!)) return false;
    final batch = _db.batch();
    batch.update(sessionDoc.reference, {'checkedInUids': FieldValue.arrayUnion([uid])});
    final attRef = _db.collection('attendance').doc();
    batch.set(attRef, AttendanceRecord(id: attRef.id, uid: uid,
      sessionId: session.id, date: DateTime.now(), present: true).toFirestore());
    batch.update(_db.collection('users').doc(uid),
      {'attendanceCount': FieldValue.increment(1), 'streak': FieldValue.increment(1)});
    await batch.commit();
    return true;
  }

  Stream<List<AttendanceRecord>> streamUserAttendance(String uid, {int days = 60}) {
    final since = DateTime.now().subtract(Duration(days: days));
    return _db.collection('attendance').where('uid', isEqualTo: uid)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .orderBy('date', descending: true).snapshots()
      .map((s) => s.docs.map(AttendanceRecord.fromFirestore).toList());
  }

  Stream<List<SongModel>> streamSongs({SongType? type}) {
    Query query = _db.collection('songs').orderBy('title');
    if (type != null) query = query.where('type', isEqualTo: type.name);
    return query.snapshots().map((s) => s.docs.map(SongModel.fromFirestore).toList());
  }

  Future<void> addSong(SongModel song) =>
    _db.collection('songs').doc(song.id).set(song.toFirestore());

  Future<void> deleteSong(String id) => _db.collection('songs').doc(id).delete();

  Future<void> postQuietTime(QuietTimePost post) =>
    _db.collection('quiet_time').doc(post.id).set(post.toFirestore());

  Stream<List<QuietTimePost>> streamQuietTimePosts({int limit = 20}) => _db
    .collection('quiet_time').orderBy('date', descending: true).limit(limit)
    .snapshots().map((s) => s.docs.map(QuietTimePost.fromFirestore).toList());

  Stream<DevotionalModel?> streamTodayDevotional() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return _db.collection('devotionals')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end)).limit(1).snapshots()
      .map((s) => s.docs.isEmpty ? null : DevotionalModel.fromFirestore(s.docs.first));
  }

  Future<void> saveDevotional(DevotionalModel d) =>
    _db.collection('devotionals').doc(d.id).set(d.toFirestore());

  Stream<List<AnnouncementModel>> streamAnnouncements({int limit = 10}) => _db
    .collection('announcements').orderBy('date', descending: true).limit(limit)
    .snapshots().map((s) => s.docs.map(AnnouncementModel.fromFirestore).toList());

  Future<void> addAnnouncement(AnnouncementModel a) =>
    _db.collection('announcements').doc(a.id).set(a.toFirestore());

  Future<void> deleteAnnouncement(String id) =>
    _db.collection('announcements').doc(id).delete();

  Stream<List<RehearsalModel>> streamUpcomingRehearsals() => _db.collection('rehearsals')
    .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
    .orderBy('dateTime').snapshots()
    .map((s) => s.docs.map(RehearsalModel.fromFirestore).toList());

  Future<void> addRehearsal(RehearsalModel r) =>
    _db.collection('rehearsals').doc(r.id).set(r.toFirestore());

  Future<void> deleteRehearsal(String id) =>
    _db.collection('rehearsals').doc(id).delete();

  Future<Map<String, int>> getAdminStats() async {
    final users = await _db.collection('users').get();
    final pending = users.docs.where((d) => d['isApproved'] == false).length;
    final complete = users.docs.where((d) {
      final data = d.data();
      return data['name'] != null && data['email'] != null &&
        data['phone'] != null && data['voicePart'] != null;
    }).length;
    final activeSessions = await _db.collection('sessions')
      .where('isActive', isEqualTo: true).count().get();
    return {'totalMembers': users.docs.length, 'completeProfiles': complete,
      'pendingSetup': pending, 'activeSessions': activeSessions.count ?? 0};
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/providers/providers.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\providers\providers.dart" @'
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

final songsProvider = StreamProvider.family<List<SongModel>, SongType?>((ref, type) =>
  ref.watch(firestoreServiceProvider).streamSongs(type: type));

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
# lib/shared/widgets/main_shell.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\shared\widgets\main_shell.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/communication')) return 2;
    if (location.startsWith('/admin')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/schedule'); break;
            case 2: context.go('/communication'); break;
            case 3: context.go('/admin'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Communica...'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# Stub screens (these will be replaced with full code next)
# ══════════════════════════════════════════════════════════════════════════════
$stubs = @{
  "$base\features\schedule\schedule_screen.dart" = @("ScheduleScreen", "Schedule")
  "$base\features\admin\admin_screen.dart" = @("AdminScreen", "Admin Dashboard")
  "$base\features\checkin\checkin_screen.dart" = @("CheckInScreen", "Check In")
  "$base\features\attendance\attendance_history_screen.dart" = @("AttendanceHistoryScreen", "Attendance History")
  "$base\features\music\music_library_screen.dart" = @("MusicLibraryScreen", "Music Library")
  "$base\features\quiet_time\quiet_time_screen.dart" = @("QuietTimeScreen", "Quiet Time")
  "$base\features\profile\profile_screen.dart" = @("ProfileScreen", "Profile")
  "$base\features\directory\directory_screen.dart" = @("DirectoryScreen", "Directory")
  "$base\features\announcements\announcements_screen.dart" = @("AnnouncementsScreen", "Announcements")
}

foreach ($entry in $stubs.GetEnumerator()) {
  $class = $entry.Value[0]
  $title = $entry.Value[1]
  Write-File $entry.Key @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class $class extends ConsumerWidget {
  const $class({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: const Center(child: Text('Coming soon...')),
    );
  }
}
"@
}

# ══════════════════════════════════════════════════════════════════════════════
# lib/features/auth/login_screen.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\features\auth\login_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false, _obscurePass = true;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).login(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
    } catch (e) {
      setState(() => _error = 'Invalid email or password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryLight])),
        child: SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 96, height: 96,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.music_note, size: 52, color: AppColors.primary)),
            const SizedBox(height: 20),
            const Text('Asempa Choir', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('NUPS-G UMaT', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _passCtrl, obscureText: _obscurePass,
                  decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass))),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)))
                ],
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _loading ? null : _login,
                  child: _loading ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign In')),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? "),
                  GestureDetector(onTap: () => context.push('/register'),
                    child: const Text('Register', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
                ]),
              ])),
            ),
          ]),
        ))),
      ),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/features/auth/register_screen.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\features\auth\register_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _voicePart = 'SOPRANO';
  bool _loading = false, _obscurePass = true;
  String? _error;

  static const _parts = ['SOPRANO','ALTO','TENOR','BASS','PIANO','DRUMS','GUITAR'];

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).register(
        name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(),
        password: _passCtrl.text, phone: _phoneCtrl.text.trim(), voicePart: _voicePart);
      if (mounted) context.go('/home');
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.contains('email-already-in-use')
        ? 'Email already registered.' : 'Registration failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(children: [
          const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(controller: _nameCtrl, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined), hintText: '+233...'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(value: _voicePart,
                decoration: const InputDecoration(labelText: 'Voice / Instrument', prefixIcon: Icon(Icons.music_note_outlined)),
                items: _parts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _voicePart = v!)),
              const SizedBox(height: 16),
              TextFormField(controller: _passCtrl, obscureText: _obscurePass,
                decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass))),
                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)))
              ],
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _loading ? null : _register,
                child: _loading ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Account')),
            ])),
          ),
        ]),
      )),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/router/router.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\router\router.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/checkin/checkin_screen.dart';
import '../features/attendance/attendance_history_screen.dart';
import '../features/music/music_library_screen.dart';
import '../features/quiet_time/quiet_time_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/directory/directory_screen.dart';
import '../features/announcements/announcements_screen.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
          GoRoute(path: '/communication', builder: (_, __) => const _UnderConstruction()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
        ],
      ),
      GoRoute(path: '/checkin', builder: (_, __) => const CheckInScreen()),
      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceHistoryScreen()),
      GoRoute(path: '/music', builder: (_, __) => const MusicLibraryScreen()),
      GoRoute(path: '/quiet-time', builder: (_, __) => const QuietTimeScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/directory', builder: (_, __) => const DirectoryScreen()),
      GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsScreen()),
    ],
  );
});

class _UnderConstruction extends StatelessWidget {
  const _UnderConstruction();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communication')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.construction, size: 80, color: Colors.orange.shade400),
        const SizedBox(height: 24),
        Text('Under Construction', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text('Group chat, announcements and messaging\ncoming soon!',
          textAlign: TextAlign.center),
      ])),
    );
  }
}
'@

# ══════════════════════════════════════════════════════════════════════════════
# lib/features/home/home_screen.dart
# ══════════════════════════════════════════════════════════════════════════════
Write-File "$base\features\home\home_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final songsAsync = ref.watch(songsProvider(null));
    final rehearsalsAsync = ref.watch(upcomingRehearsalsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Asempa Choir'),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})]),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox();
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                CircleAvatar(radius: 30, backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white, size: 32)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(user.voicePart, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            Text('Quick Stats', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard(icon: Icons.check_circle, iconColor: AppColors.success,
                value: user.attendanceCount.toString(), label: 'Attendance')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.local_fire_department, iconColor: AppColors.warning,
                value: user.streak.toString(), label: 'Streak')),
            ]),
            const SizedBox(height: 20),
            // Recent Songs
            songsAsync.when(
              loading: () => const SizedBox(), error: (_, __) => const SizedBox(),
              data: (songs) => songs.isEmpty ? const SizedBox() : _SectionCard(
                icon: Icons.music_note, title: 'Recent Songs',
                onViewAll: () => context.push('/music'),
                children: songs.take(4).map((s) => ListTile(contentPadding: EdgeInsets.zero,
                  title: Text(s.title, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: s.artist != null ? Text(s.artist!) : null,
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList()),
            ),
            const SizedBox(height: 16),
            // Rehearsals
            _SectionCard(icon: Icons.calendar_today, title: 'Upcoming Rehearsals',
              onViewAll: () => context.push('/schedule'),
              children: rehearsalsAsync.when(
                loading: () => [const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (r) => r.isEmpty
                  ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No upcoming rehearsals scheduled', style: Theme.of(context).textTheme.bodyMedium))]
                  : r.take(3).map((reh) => ListTile(contentPadding: EdgeInsets.zero,
                      title: Text(reh.title), subtitle: Text(DateFormat('EEE, MMM d • h:mm a').format(reh.dateTime)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 16),
            // Announcements
            _SectionCard(icon: Icons.campaign, title: 'Recent Announcements',
              children: announcementsAsync.when(
                loading: () => [const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))],
                error: (_, __) => [],
                data: (items) => items.isEmpty
                  ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No announcements', style: Theme.of(context).textTheme.bodyMedium))]
                  : items.take(3).map((a) => ListTile(contentPadding: EdgeInsets.zero,
                      title: Text(a.title), subtitle: Text(DateFormat('d MMM y').format(a.date)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint))).toList())),
            const SizedBox(height: 20),
            Text('More Features', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _Feature(icon: Icons.group, label: 'Directory', color: Colors.blue.shade100, iconColor: Colors.blue, onTap: () => context.push('/directory')),
            _Feature(icon: Icons.person, label: 'Profile', color: Colors.purple.shade100, iconColor: Colors.purple, onTap: () => context.push('/profile')),
            _Feature(icon: Icons.menu_book, label: 'Quiet Time', color: Colors.teal.shade100, iconColor: Colors.teal, onTap: () => context.push('/quiet-time')),
            _Feature(icon: Icons.library_music, label: 'Music', color: Colors.orange.shade100, iconColor: Colors.orange, onTap: () => context.push('/music')),
            _Feature(icon: Icons.qr_code_scanner, label: 'Check In', color: Colors.green.shade100, iconColor: Colors.green, onTap: () => context.push('/checkin')),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final Color iconColor; final String value, label;
  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider.withOpacity(0.5))),
    child: Column(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 24)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: iconColor)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final IconData icon; final String title; final List<Widget> children; final VoidCallback? onViewAll;
  const _SectionCard({required this.icon, required this.title, required this.children, this.onViewAll});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider.withOpacity(0.5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: AppColors.textSecondary)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('See all')),
      ]),
      ...children,
    ]),
  );
}

class _Feature extends StatelessWidget {
  final IconData icon; final String label; final Color color, iconColor; final VoidCallback onTap;
  const _Feature({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22)),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap),
  );
}
'@

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " All files created successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: flutter pub get" -ForegroundColor White
Write-Host "  2. Set up Firebase (tell me when ready)" -ForegroundColor White
Write-Host "  3. Run: flutter run" -ForegroundColor White
Write-Host ""
