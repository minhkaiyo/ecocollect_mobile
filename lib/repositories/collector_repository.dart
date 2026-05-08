import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_profile.dart';
import 'base_repository.dart';

class CollectorRepository extends BaseRepository {
  CollectionReference get _collection => db.collection('users');

  Future<List<UserProfile>> searchByName(String query) async {
    if (query.isEmpty) return [];
    
    // Tìm kiếm đơn giản (do Firestore không hỗ trợ full text search tự nhiên tốt)
    final snap = await _collection
        .where('role', isEqualTo: 'collector')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
        
    return snap.docs.map(UserProfile.fromFirestore).toList();
  }

  Future<UserProfile?> findByPhone(String phone) async {
    final snap = await _collection
        .where('role', isEqualTo: 'collector')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
        
    if (snap.docs.isEmpty) return null;
    return UserProfile.fromFirestore(snap.docs.first);
  }

  Future<List<UserProfile>> findNearby(LatLng from, {double radiusKm = 5.0}) async {
    final snap = await _collection
        .where('role', isEqualTo: 'collector')
        .get();
        
    final all = snap.docs.map(UserProfile.fromFirestore).toList();
    final dist = Distance();
    
    // Lọc theo khoảng cách
    final nearby = all.where((u) {
      if (u.location == null) return false;
      final d = dist(from, LatLng(u.location!.latitude, u.location!.longitude));
      return (d / 1000) <= radiusKm;
    }).toList();
    
    // Sắp xếp gần nhất
    nearby.sort((a, b) {
      final da = dist(from, LatLng(a.location!.latitude, a.location!.longitude));
      final db = dist(from, LatLng(b.location!.latitude, b.location!.longitude));
      return da.compareTo(db);
    });
    
    return nearby;
  }
}
