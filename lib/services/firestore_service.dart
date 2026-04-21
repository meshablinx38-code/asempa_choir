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