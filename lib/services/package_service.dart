// lib/services/package_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/package_model.dart';

class PackageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = 'packages';

  Stream<List<PackageModel>> getPackagesStream(String restaurantId) {
    return _db
        .collection(_collectionPath)
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PackageModel.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<DocumentReference> addPackage(Map<String, dynamic> data) async {
    return await _db.collection(_collectionPath).add(data);
  }

  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await _db.collection(_collectionPath).doc(id).update(data);
  }

  Future<void> deletePackage(String id) async {
    await _db.collection(_collectionPath).doc(id).delete();
  }
}
