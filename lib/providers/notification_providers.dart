import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Counts of unread items for admin notifications
final pendingMembersCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance.collection('users')
    .where('isApproved', isEqualTo: false)
    .snapshots().map((s) => s.docs.length);
});

final unreadSuggestionsCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance.collection('suggestions')
    .where('isRead', isEqualTo: false)
    .snapshots().map((s) => s.docs.length);
});

final pendingTestimoniesCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance.collection('testimonies')
    .where('isApproved', isEqualTo: false)
    .snapshots().map((s) => s.docs.length);
});

final totalAdminNotificationsProvider = StreamProvider<int>((ref) {
  final pending = ref.watch(pendingMembersCountProvider).valueOrNull ?? 0;
  final suggestions = ref.watch(unreadSuggestionsCountProvider).valueOrNull ?? 0;
  final testimonies = ref.watch(pendingTestimoniesCountProvider).valueOrNull ?? 0;
  return Stream.value(pending + suggestions + testimonies);
});
