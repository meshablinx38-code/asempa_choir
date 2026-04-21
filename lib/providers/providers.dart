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