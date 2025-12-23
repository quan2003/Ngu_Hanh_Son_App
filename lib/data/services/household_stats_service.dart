import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/household_stats.dart';

class HouseholdStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'household_stats';

  /// Get all household statistics
  Stream<List<HouseholdStats>> getHouseholdStats() {
    return _firestore
        .collection(collectionName)
        .orderBy('tdpName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['tdpId'] = doc.id;
        return HouseholdStats.fromJson(data);
      }).toList();
    });
  }

  /// Get statistics for a specific TDP
  Future<HouseholdStats?> getStatsByTdpId(String tdpId) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(tdpId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['tdpId'] = doc.id;
        return HouseholdStats.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting stats for TDP $tdpId: $e');
      return null;
    }
  }

  /// Add or update household statistics
  Future<void> setHouseholdStats(HouseholdStats stats) async {
    try {
      await _firestore.collection(collectionName).doc(stats.tdpId).set(
            stats.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error setting household stats: $e');
      rethrow;
    }
  }

  /// Get total statistics across all TDPs
  Future<Map<String, int>> getTotalStats() async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();

      int totalOldHouseholds = 0;
      int totalReportedHouseholds = 0;
      int totalPopulation = 0;
      int totalPoorCity = 0;
      int totalPoorCentral = 0;
      int totalNearPoorCity = 0;
      int totalNearPoorCentral = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalOldHouseholds += (data['oldHouseholdCount'] as int? ?? 0);
        totalReportedHouseholds +=
            (data['reportedHouseholdCount'] as int? ?? 0);
        totalPopulation += (data['populationCount'] as int? ?? 0);
        totalPoorCity += (data['poorHouseholdCity'] as int? ?? 0);
        totalPoorCentral += (data['poorHouseholdCentral'] as int? ?? 0);
        totalNearPoorCity += (data['nearPoorHouseholdCity'] as int? ?? 0);
        totalNearPoorCentral += (data['nearPoorHouseholdCentral'] as int? ?? 0);
      }

      return {
        'oldHouseholdCount': totalOldHouseholds,
        'reportedHouseholdCount': totalReportedHouseholds,
        'populationCount': totalPopulation,
        'poorHouseholdCity': totalPoorCity,
        'poorHouseholdCentral': totalPoorCentral,
        'nearPoorHouseholdCity': totalNearPoorCity,
        'nearPoorHouseholdCentral': totalNearPoorCentral,
      };
    } catch (e) {
      print('Error getting total stats: $e');
      return {
        'oldHouseholdCount': 0,
        'reportedHouseholdCount': 0,
        'populationCount': 0,
        'poorHouseholdCity': 0,
        'poorHouseholdCentral': 0,
        'nearPoorHouseholdCity': 0,
        'nearPoorHouseholdCentral': 0,
      };
    }
  }

  /// Delete household statistics for a TDP
  Future<void> deleteStats(String tdpId) async {
    try {
      await _firestore.collection(collectionName).doc(tdpId).delete();
    } catch (e) {
      print('Error deleting stats: $e');
      rethrow;
    }
  }
}
