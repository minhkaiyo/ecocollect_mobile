import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../utils/error_handler.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';

/// Repository for managing user profiles in Firestore
class UserRepository extends BaseRepository {
  final CollectionReference _collection = 
      FirebaseFirestore.instance.collection('users');

  /// Create a new user profile if it doesn't exist
  /// 
  /// This is typically called after successful authentication
  Future<void> createUserIfNotExists(User user) async {
    try {
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
          maxPickupLocations: AppConstants.maxPickupLocationsDefault,
        );
        await docRef.set(newProfile.toFirestore());
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể tạo hồ sơ người dùng: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Watch user profile changes in real-time
  /// 
  /// Returns a stream that emits the user profile whenever it changes
  Stream<UserProfile> watchProfile(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        // Return a default profile if document doesn't exist
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
          maxPickupLocations: AppConstants.maxPickupLocationsDefault,
        );
      }
      return UserProfile.fromFirestore(doc);
    }).handleError((error, stackTrace) {
      ErrorHandler.logError(error, stackTrace);
      // Return a default profile on error to prevent stream from breaking
      return UserProfile(
        uid: uid,
        displayName: 'Lỗi tải dữ liệu',
        phone: '',
        address: '',
        greenPoints: 0,
        totalKgRecycled: 0,
        totalOrders: 0,
        createdAt: DateTime.now(),
        role: 'seller',
        maxPickupLocations: AppConstants.maxPickupLocationsDefault,
      );
    });
  }

  /// Get user profile once
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _collection.doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return null;
    }
  }

  /// Update user profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _collection.doc(uid).update(data);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể cập nhật hồ sơ: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Save a partner (collector/station) to user's saved list
  Future<void> savePartner(String myUid, String partnerUid) async {
    try {
      await _collection.doc(myUid).update({
        'savedPartners': FieldValue.arrayUnion([partnerUid])
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể lưu đối tác: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Remove a partner from user's saved list
  Future<void> removePartner(String myUid, String partnerUid) async {
    try {
      await _collection.doc(myUid).update({
        'savedPartners': FieldValue.arrayRemove([partnerUid])
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể xóa đối tác: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Watch saved partners in real-time
  /// 
  /// Firestore has a limit of 10 items in whereIn query, so we chunk the requests
  Stream<List<UserProfile>> watchSavedPartners(String myUid) {
    return _collection.doc(myUid).snapshots().asyncMap((doc) async {
      try {
        if (!doc.exists) return <UserProfile>[];
        
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final savedIds = List<String>.from(data['savedPartners'] as List? ?? []);
        
        if (savedIds.isEmpty) return <UserProfile>[];

        // Chunk into groups of 10 (Firestore whereIn limit)
        final chunks = <List<String>>[];
        for (var i = 0; i < savedIds.length; i += AppConstants.maxSavedPartnersPerQuery) {
          final end = (i + AppConstants.maxSavedPartnersPerQuery > savedIds.length)
              ? savedIds.length
              : i + AppConstants.maxSavedPartnersPerQuery;
          chunks.add(savedIds.sublist(i, end));
        }

        final List<UserProfile> partners = [];
        for (final chunk in chunks) {
          final querySnap = await _collection
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          partners.addAll(
            querySnap.docs.map((d) => UserProfile.fromFirestore(d))
          );
        }
        
        return partners;
      } catch (e, stackTrace) {
        ErrorHandler.logError(e, stackTrace);
        return <UserProfile>[];
      }
    }).handleError((error, stackTrace) {
      ErrorHandler.logError(error, stackTrace);
      return Stream.value(<UserProfile>[]);
    }).cast<List<UserProfile>>();
  }
}
