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
      );
      await docRef.set(newProfile.toFirestore());
    }
  }

  Stream<UserProfile> watchProfile(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('User profile not found');
      }
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _collection.doc(uid).update(data);
  }
}
