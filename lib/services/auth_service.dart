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