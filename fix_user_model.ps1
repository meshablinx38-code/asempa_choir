$model = @'
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { member, admin }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String voicePart;
  final String? hostel;
  final String? level;
  final String? memberType;
  final List<String> instruments;
  final UserRole role;
  final String? photoUrl;
  final DateTime joinedAt;
  final DateTime? lastLoginAt;
  final bool isApproved;
  final bool isActive;
  final int attendanceCount;
  final int streak;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.voicePart,
    this.hostel,
    this.level,
    this.memberType,
    this.instruments = const [],
    required this.role,
    this.photoUrl,
    required this.joinedAt,
    this.lastLoginAt,
    required this.isApproved,
    this.isActive = true,
    this.attendanceCount = 0,
    this.streak = 0,
  });

  bool get isAdmin => role == UserRole.admin;
  String get firstName => name.split(' ').first;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Handle instruments array
    List<String> instrumentList = [];
    if (d['instruments'] != null) {
      instrumentList = List<String>.from(d['instruments']);
    }

    // Determine voice part - check voicePart first, then mainInstrument
    String vp = '';
    if (d['voicePart'] != null && d['voicePart'].toString().isNotEmpty) {
      vp = d['voicePart'].toString();
    } else if (d['mainInstrument'] != null && d['mainInstrument'].toString().isNotEmpty) {
      vp = d['mainInstrument'].toString();
    } else if (instrumentList.isNotEmpty) {
      vp = instrumentList.first;
    } else {
      vp = 'Member';
    }

    return UserModel(
      uid: doc.id,
      name: d['fullName'] ?? d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phoneNumber'] ?? d['phone'] ?? '',
      voicePart: vp,
      hostel: d['hostel'],
      level: d['level']?.toString(),
      memberType: d['memberType'],
      instruments: instrumentList,
      role: (d['isAdmin'] == true || d['role'] == 'admin')
          ? UserRole.admin : UserRole.member,
      photoUrl: d['profilePhotoUrl'] ?? d['photoUrl'],
      joinedAt: (d['joinedDate'] as Timestamp?)?.toDate() ??
          (d['joinedAt'] as Timestamp?)?.toDate() ??
          (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      lastLoginAt: (d['lastAccessDate'] as Timestamp?)?.toDate() ??
          (d['lastLoginAt'] as Timestamp?)?.toDate(),
      isApproved: d['isApproved'] ?? false,
      isActive: d['isActive'] ?? true,
      attendanceCount: d['attendanceCount'] ?? 0,
      streak: d['dailyStreak'] ?? d['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fullName': name,
    'email': email,
    'phoneNumber': phone,
    'voicePart': voicePart,
    'mainInstrument': voicePart,
    'hostel': hostel,
    'level': level,
    'memberType': memberType,
    'instruments': instruments,
    'isAdmin': role == UserRole.admin,
    'role': role == UserRole.admin ? 'admin' : 'member',
    'profilePhotoUrl': photoUrl,
    'joinedDate': Timestamp.fromDate(joinedAt),
    'lastAccessDate': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    'isApproved': isApproved,
    'isActive': isActive,
    'attendanceCount': attendanceCount,
    'dailyStreak': streak,
  };

  UserModel copyWith({
    String? name, String? phone, String? voicePart, String? hostel,
    String? level, String? memberType, String? photoUrl,
    bool? isApproved, bool? isActive, int? attendanceCount, int? streak,
  }) {
    return UserModel(
      uid: uid, name: name ?? this.name, email: email,
      phone: phone ?? this.phone, voicePart: voicePart ?? this.voicePart,
      hostel: hostel ?? this.hostel, level: level ?? this.level,
      memberType: memberType ?? this.memberType, instruments: instruments,
      role: role, photoUrl: photoUrl ?? this.photoUrl, joinedAt: joinedAt,
      lastLoginAt: lastLoginAt, isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      streak: streak ?? this.streak,
    );
  }
}
'@

[System.IO.File]::WriteAllText("lib\models\user_model.dart", $model, [System.Text.Encoding]::UTF8)
Write-Host "user_model.dart fixed to match Firestore!" -ForegroundColor Green
Write-Host "Press r in the Flutter terminal to hot reload" -ForegroundColor Yellow
