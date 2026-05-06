import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/pickup_location.dart';
import 'base_repository.dart';

class PickupLocationRepository extends BaseRepository {
  CollectionReference<Map<String, dynamic>> get _collection =>
      db.collection('pickup_locations');

  Stream<List<PickupLocation>> watchAllLocations() {
    return _collection
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(PickupLocation.fromFirestore).toList());
  }

  Stream<List<PickupLocation>> watchOwnerLocations(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(PickupLocation.fromFirestore).toList());
  }

  Future<void> addLocation({
    required String ownerId,
    required String ownerName,
    required String label,
    required String address,
    required double lat,
    required double lng,
    required int maxLocations,
  }) async {
    final existing = await _collection
        .where('ownerId', isEqualTo: ownerId)
        .where('active', isEqualTo: true)
        .count()
        .get();
    if ((existing.count ?? 0) >= maxLocations) {
      throw Exception(
        'Bạn đã đạt giới hạn $maxLocations điểm thu mua. Vui lòng nạp tiền để mở thêm.',
      );
    }
    await _collection.doc().set({
      'ownerId': ownerId,
      'ownerName': ownerName,
      'label': label,
      'address': address,
      'geoPoint': GeoPoint(lat, lng),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<PickupLocation?> findNearest(LatLng from) async {
    final docs = await _collection.where('active', isEqualTo: true).get();
    if (docs.docs.isEmpty) return null;
    final all = docs.docs.map(PickupLocation.fromFirestore).toList();
    final dist = Distance();
    all.sort((a, b) {
      final da = dist(from, LatLng(a.geoPoint.latitude, a.geoPoint.longitude));
      final dbb = dist(from, LatLng(b.geoPoint.latitude, b.geoPoint.longitude));
      return da.compareTo(dbb);
    });
    return all.first;
  }

  Future<List<PickupLocation>> findNearestN(LatLng from, {int count = 3}) async {
    final docs = await _collection.where('active', isEqualTo: true).get();
    if (docs.docs.isEmpty) return [];
    final all = docs.docs.map(PickupLocation.fromFirestore).toList();
    final dist = Distance();
    all.sort((a, b) {
      final da = dist(from, LatLng(a.geoPoint.latitude, a.geoPoint.longitude));
      final dbb = dist(from, LatLng(b.geoPoint.latitude, b.geoPoint.longitude));
      return da.compareTo(dbb);
    });
    return all.take(count).toList();
  }
}
