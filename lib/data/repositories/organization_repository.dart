import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/to_chuc_dang.dart';
import '../../domain/entities/to_dan_pho.dart';

class OrganizationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _toChucDangCollection = 'to_chuc_dang';
  static const String _toDanPhoCollection = 'to_dan_pho';

  /// Get all Tổ chức Đảng
  Future<List<ToChucDang>> getAllToChucDang() async {
    try {
      final snapshot = await _firestore
          .collection(_toChucDangCollection)
          .orderBy('stt')
          .get();
      return snapshot.docs
          .map((doc) => ToChucDang.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching ToChucDang: $e');
      rethrow;
    }
  }

  /// Get Tổ chức Đảng by ID
  Future<ToChucDang?> getToChucDangById(String id) async {
    try {
      final doc =
          await _firestore.collection(_toChucDangCollection).doc(id).get();
      if (doc.exists) {
        return ToChucDang.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error fetching ToChucDang: $e');
      rethrow;
    }
  }

  /// Stream Tổ chức Đảng
  Stream<List<ToChucDang>> getToChucDangStream() {
    return _firestore
        .collection(_toChucDangCollection)
        .orderBy('stt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ToChucDang.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get all Tổ dân phố
  Future<List<ToDanPho>> getAllToDanPho() async {
    try {
      final snapshot = await _firestore.collection(_toDanPhoCollection).get();
      return snapshot.docs
          .map((doc) => ToDanPho.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching ToDanPho: $e');
      rethrow;
    }
  }

  /// Get Tổ dân phố by ID
  Future<ToDanPho?> getToDanPhoById(String id) async {
    try {
      final doc =
          await _firestore.collection(_toDanPhoCollection).doc(id).get();
      if (doc.exists) {
        return ToDanPho.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error fetching ToDanPho: $e');
      rethrow;
    }
  }

  /// Stream Tổ dân phố
  Stream<List<ToDanPho>> getToDanPhoStream() {
    return _firestore.collection(_toDanPhoCollection).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ToDanPho.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Search Tổ chức Đảng by name
  Future<List<ToChucDang>> searchToChucDang(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_toChucDangCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();
      return snapshot.docs
          .map((doc) => ToChucDang.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error searching ToChucDang: $e');
      rethrow;
    }
  }

  /// Search Tổ dân phố by name
  Future<List<ToDanPho>> searchToDanPho(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_toDanPhoCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();
      return snapshot.docs
          .map((doc) => ToDanPho.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error searching ToDanPho: $e');
      rethrow;
    }
  }

  // ==================== CREATE ====================

  /// Create new Tổ chức Đảng
  Future<void> createToChucDang(ToChucDang toChucDang) async {
    try {
      await _firestore
          .collection(_toChucDangCollection)
          .doc(toChucDang.id)
          .set(toChucDang.toJson());
      print('✅ ToChucDang created: ${toChucDang.id}');
    } catch (e) {
      print('Error creating ToChucDang: $e');
      rethrow;
    }
  }

  /// Create new Tổ dân phố
  Future<void> createToDanPho(ToDanPho toDanPho) async {
    try {
      await _firestore
          .collection(_toDanPhoCollection)
          .doc(toDanPho.id)
          .set(toDanPho.toJson());
      print('✅ ToDanPho created: ${toDanPho.id}');
    } catch (e) {
      print('Error creating ToDanPho: $e');
      rethrow;
    }
  }

  // ==================== UPDATE ====================

  /// Update Tổ chức Đảng
  Future<void> updateToChucDang(ToChucDang toChucDang) async {
    try {
      final data = toChucDang.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_toChucDangCollection)
          .doc(toChucDang.id)
          .update(data);
      print('✅ ToChucDang updated: ${toChucDang.id}');
    } catch (e) {
      print('Error updating ToChucDang: $e');
      rethrow;
    }
  }

  /// Update Tổ dân phố
  Future<void> updateToDanPho(ToDanPho toDanPho) async {
    try {
      final data = toDanPho.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_toDanPhoCollection)
          .doc(toDanPho.id)
          .update(data);
      print('✅ ToDanPho updated: ${toDanPho.id}');
    } catch (e) {
      print('Error updating ToDanPho: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  /// Delete Tổ chức Đảng
  Future<void> deleteToChucDang(String id) async {
    try {
      await _firestore.collection(_toChucDangCollection).doc(id).delete();
      print('✅ ToChucDang deleted: $id');
    } catch (e) {
      print('Error deleting ToChucDang: $e');
      rethrow;
    }
  }

  /// Delete Tổ dân phố
  Future<void> deleteToDanPho(String id) async {
    try {
      await _firestore.collection(_toDanPhoCollection).doc(id).delete();
      print('✅ ToDanPho deleted: $id');
    } catch (e) {
      print('Error deleting ToDanPho: $e');
      rethrow;
    }
  }
}
