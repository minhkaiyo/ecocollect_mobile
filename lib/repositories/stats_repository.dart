import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';

class StatsRepository extends BaseRepository {
  Stream<Map<String, dynamic>> watchGlobalStats() {
    return db.collection('app_stats').doc('global').snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'totalKgRecycled': 0.0,
          'totalRegisteredBuyers': 0,
          'totalRegisteredSellers': 0,
          'totalRecyclingStations': 0,
        };
      }
      return doc.data() as Map<String, dynamic>;
    });
  }

  Stream<double> watchUserTotalKg(String uid) {
    return db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
      double total = 0;
      for (var doc in snap.docs) {
        total += (doc.data()['weight'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    });
  }
}
