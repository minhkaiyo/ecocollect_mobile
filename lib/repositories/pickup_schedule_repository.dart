import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pickup_schedule.dart';
import 'base_repository.dart';

class PickupScheduleRepository extends BaseRepository {
  CollectionReference<Map<String, dynamic>> get _collection =>
      db.collection('pickup_schedules');

  Stream<List<PickupSchedule>> watchUserSchedules(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(PickupSchedule.fromFirestore).toList());
  }

  Future<void> createSchedule({
    required String userId,
    required String wasteType,
    required String frequency,
    required String timeSlot,
  }) async {
    await _collection.doc().set({
      'userId': userId,
      'wasteType': wasteType,
      'frequency': frequency,
      'timeSlot': timeSlot,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
