import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('users');

  Future<void> createUserIfNotExists(User user) async {
    final docRef = _collection.doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      final newProfile = UserProfile(
        uid: user.uid,
        displayName: user.displayName ?? 'Người dùng',
        phone: user.phoneNumber ?? 'Chưa cập nhật',
        address: 'Chưa cập nhật',
        photoUrl: user.photoURL,
        greenPoints: 0,
        totalKgRecycled: 0,
        totalOrders: 0,
        createdAt: DateTime.now(),
        role: 'seller',
        maxPickupLocations: 2,
      );
      await docRef.set(newProfile.toFirestore());
    }
  }

  Stream<UserProfile> watchProfile(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        return UserProfile(
          uid: uid,
          displayName: 'Đang tải...',
          phone: '',
          address: '',
          greenPoints: 0,
          totalKgRecycled: 0,
          totalOrders: 0,
          createdAt: DateTime.now(),
          role: 'seller',
          maxPickupLocations: 2,
        );
      }
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _collection.doc(uid).update(data);
  }

  Future<void> savePartner(String myUid, String partnerUid) async {
    await _collection.doc(myUid).update({
      'savedPartners': FieldValue.arrayUnion([partnerUid])
    });
  }

  Future<void> removePartner(String myUid, String partnerUid) async {
    await _collection.doc(myUid).update({
      'savedPartners': FieldValue.arrayRemove([partnerUid])
    });
  }

  Stream<List<UserProfile>> watchSavedPartners(String myUid) {
    return _collection.doc(myUid).snapshots().asyncMap((doc) async {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final savedIds = List<String>.from(data['savedPartners'] ?? []);
      if (savedIds.isEmpty) return [];

      final chunks = <List<String>>[];
      for (var i = 0; i < savedIds.length; i += 10) {
        chunks.add(savedIds.sublist(i, i + 10 > savedIds.length ? savedIds.length : i + 10));
      }

      final List<UserProfile> partners = [];
      for (final chunk in chunks) {
        final querySnap = await _collection.where(FieldPath.documentId, whereIn: chunk).get();
        partners.addAll(querySnap.docs.map((d) => UserProfile.fromFirestore(d)));
      }
      return partners;
    });
  }
}
