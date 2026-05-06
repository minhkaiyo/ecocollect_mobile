import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/paper_bank_group.dart';
import 'base_repository.dart';

class PaperBankRepository extends BaseRepository {
  Stream<List<PaperBankGroup>> watchUserGroups(String uid) {
    return db
        .collection('paper_bank_groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map(PaperBankGroup.fromFirestore).toList());
  }

  Future<void> createGroup({
    required String name,
    required String type,
    required double targetKg,
    required String uid,
  }) async {
    await db.collection('paper_bank_groups').add({
      'name': name,
      'type': type,
      'memberCount': 1,
      'totalKgCollected': 0.0,
      'targetKg': targetKg,
      'createdBy': uid,
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
      'scheduleDay': 'saturday',
    });
  }

  Future<void> addMember(String groupId, String uid) async {
    await db.collection('paper_bank_groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
      'memberCount': FieldValue.increment(1),
    });
  }
}
