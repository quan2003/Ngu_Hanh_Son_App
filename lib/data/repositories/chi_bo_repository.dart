import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/to_chuc_dang.dart';

class ChiBoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'to_chuc_dang';

  /// Get all Chi Bộ from to_chuc_dang collection
  Future<List<ToChucDang>> getAllChiBo() async {
    try {
      print('📱 Fetching Chi Bộ from Firestore...');

      // Try with filter first
      try {
        final snapshot = await _firestore
            .collection(_collection)
            .where('type', isEqualTo: 'Chi bộ')
            .orderBy('name')
            .get();

        print('✅ Found ${snapshot.docs.length} Chi Bộ documents');

        final result = snapshot.docs.map((doc) {
          print('📄 Document: ${doc.id} - ${doc.data()}');
          return ToChucDang.fromJson({...doc.data(), 'id': doc.id});
        }).toList();

        return result;
      } catch (indexError) {
        // If index error, try without orderBy
        print('⚠️  Index error, trying without orderBy: $indexError');
        final snapshot = await _firestore
            .collection(_collection)
            .where('type', isEqualTo: 'Chi bộ')
            .get();

        print('✅ Found ${snapshot.docs.length} Chi Bộ documents (no sort)');

        final result = snapshot.docs
            .map((doc) => ToChucDang.fromJson({...doc.data(), 'id': doc.id}))
            .toList();

        // Sort locally
        result.sort((a, b) => a.name.compareTo(b.name));
        return result;
      }
    } catch (e) {
      print('❌ Error fetching Chi Bộ: $e');
      print('Stack trace: ${StackTrace.current}');

      // Return empty list instead of throwing
      return [];
    }
  }

  /// Stream all Chi Bộ
  Stream<List<ToChucDang>> getChiBoStream() {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'Chi bộ')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ToChucDang.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get Chi Bộ by ID
  Future<ToChucDang?> getChiBoById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ToChucDang.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error fetching Chi Bộ by ID: $e');
      return null;
    }
  }

  /// Search Chi Bộ by name
  Future<List<ToChucDang>> searchChiBo(String query) async {
    try {
      if (query.isEmpty) {
        return getAllChiBo();
      }

      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: 'Chi bộ')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();

      return snapshot.docs
          .map((doc) => ToChucDang.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error searching Chi Bộ: $e');
      // Fallback to client-side search
      final all = await getAllChiBo();
      return all
          .where((cb) => cb.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final chiBos = await getAllChiBo();

      return {
        'totalChiBo': chiBos.length,
        'withSecretary': chiBos.where((cb) => cb.secretary.isNotEmpty).length,
        'withOfficer':
            chiBos.where((cb) => cb.officerInCharge.isNotEmpty).length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  /// Debug: Get all documents to check structure
  Future<void> debugAllDocuments() async {
    try {
      print('🔍 DEBUG: Fetching ALL documents from $_collection...');
      final snapshot = await _firestore.collection(_collection).get();

      print('📊 Total documents in collection: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📄 Doc ID: ${doc.id}');
        print('   - type: "${data['type']}"');
        print('   - name: "${data['name']}"');
        print('   ---');
      }

      // Count by type
      final typeCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final type = doc.data()['type'] as String? ?? 'unknown';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      print('📈 Documents by type:');
      typeCounts.forEach((type, count) {
        print('   - "$type": $count documents');
      });
    } catch (e) {
      print('❌ Error in debug: $e');
    }
  }
}
