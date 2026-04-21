import 'package:cloud_firestore/cloud_firestore.dart';

enum SongType { fullSong, vocalPart, stem, recording }

// â”€â”€ Song â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Session â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Attendance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Quiet Time Post â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Devotional â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Announcement â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Rehearsal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ YouTube Link â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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