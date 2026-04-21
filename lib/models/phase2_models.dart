import 'package:cloud_firestore/cloud_firestore.dart';

class TestimonyModel {
  final String id, userId, fullName, voicePart, title, content;
  final bool isAnonymous, isApproved;
  final DateTime createdAt;
  final List<String> likes;
  const TestimonyModel({required this.id, required this.userId, required this.fullName, required this.voicePart, required this.title, required this.content, this.isAnonymous = false, this.isApproved = false, required this.createdAt, this.likes = const []});
  factory TestimonyModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TestimonyModel(id: doc.id, userId: d['userId'] ?? '', fullName: d['fullName'] ?? 'Anonymous', voicePart: d['voicePart'] ?? '', title: d['title'] ?? '', content: d['content'] ?? '', isAnonymous: d['isAnonymous'] ?? false, isApproved: d['isApproved'] ?? false, createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), likes: List<String>.from(d['likes'] ?? []));
  }
  Map<String, dynamic> toFirestore() => {'userId': userId, 'fullName': fullName, 'voicePart': voicePart, 'title': title, 'content': content, 'isAnonymous': isAnonymous, 'isApproved': isApproved, 'createdAt': Timestamp.fromDate(createdAt), 'likes': likes};
}

class ShoutoutModel {
  final String id, fromUserId, fromName, toUserId, toName, message;
  final String? fromVoicePart, toVoicePart;
  final DateTime createdAt;
  final List<String> likes;
  const ShoutoutModel({required this.id, required this.fromUserId, required this.fromName, required this.toUserId, required this.toName, required this.message, this.fromVoicePart, this.toVoicePart, required this.createdAt, this.likes = const []});
  factory ShoutoutModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShoutoutModel(id: doc.id, fromUserId: d['fromUserId'] ?? '', fromName: d['fromName'] ?? '', toUserId: d['toUserId'] ?? '', toName: d['toName'] ?? '', message: d['message'] ?? '', fromVoicePart: d['fromVoicePart'], toVoicePart: d['toVoicePart'], createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), likes: List<String>.from(d['likes'] ?? []));
  }
  Map<String, dynamic> toFirestore() => {'fromUserId': fromUserId, 'fromName': fromName, 'toUserId': toUserId, 'toName': toName, 'message': message, 'fromVoicePart': fromVoicePart, 'toVoicePart': toVoicePart, 'createdAt': Timestamp.fromDate(createdAt), 'likes': likes};
}

class PollModel {
  final String id, question, createdBy;
  final List<String> options;
  final Map<String, List<String>> votes;
  final DateTime createdAt;
  final bool isActive;
  const PollModel({required this.id, required this.question, required this.createdBy, required this.options, this.votes = const {}, required this.createdAt, this.isActive = true});
  int votesFor(String option) => (votes[option] ?? []).length;
  int get totalVotes => votes.values.fold(0, (sum, v) => sum + v.length);
  String? userVote(String uid) { for (final e in votes.entries) { if (e.value.contains(uid)) return e.key; } return null; }
  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final vr = d['votes'] as Map<String, dynamic>? ?? {};
    return PollModel(id: doc.id, question: d['question'] ?? '', createdBy: d['createdBy'] ?? '', options: List<String>.from(d['options'] ?? []), votes: vr.map((k, v) => MapEntry(k, List<String>.from(v))), createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), isActive: d['isActive'] ?? true);
  }
  Map<String, dynamic> toFirestore() => {'question': question, 'createdBy': createdBy, 'options': options, 'votes': votes, 'createdAt': Timestamp.fromDate(createdAt), 'isActive': isActive};
}

class SuggestionModel {
  final String id, content;
  final String? userId;
  final DateTime createdAt;
  final bool isRead;
  const SuggestionModel({required this.id, required this.content, this.userId, required this.createdAt, this.isRead = false});
  factory SuggestionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SuggestionModel(id: doc.id, content: d['content'] ?? '', userId: d['userId'], isRead: d['isRead'] ?? false, createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now());
  }
  Map<String, dynamic> toFirestore() => {'content': content, 'userId': userId, 'isRead': isRead, 'createdAt': Timestamp.fromDate(createdAt)};
}

class GalleryPhoto {
  final String id, imageUrl, caption, uploadedBy, uploadedByName;
  final DateTime uploadedAt;
  final List<String> likes;
  const GalleryPhoto({required this.id, required this.imageUrl, required this.caption, required this.uploadedBy, required this.uploadedByName, required this.uploadedAt, this.likes = const []});
  factory GalleryPhoto.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GalleryPhoto(id: doc.id, imageUrl: d['imageUrl'] ?? '', caption: d['caption'] ?? '', uploadedBy: d['uploadedBy'] ?? '', uploadedByName: d['uploadedByName'] ?? '', uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(), likes: List<String>.from(d['likes'] ?? []));
  }
  Map<String, dynamic> toFirestore() => {'imageUrl': imageUrl, 'caption': caption, 'uploadedBy': uploadedBy, 'uploadedByName': uploadedByName, 'uploadedAt': Timestamp.fromDate(uploadedAt), 'likes': likes};
}