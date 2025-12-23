import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhs_dangbo_app/domain/models/administrative_unit.dart';

/// Service for managing administrative units (Chi bộ, Tổ dân phố, etc.)
class AdministrativeUnitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _collectionName = 'administrative_units';
  
  /// Get all administrative units
  Stream<List<AdministrativeUnit>> getUnits() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdministrativeUnit.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }
  
  /// Get units by type (chi_bo, to_dan_pho, phuong)
  Stream<List<AdministrativeUnit>> getUnitsByType(String type) {
    return _firestore
        .collection(_collectionName)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdministrativeUnit.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }
  
  /// Get a single unit by ID
  Future<AdministrativeUnit?> getUnit(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (!doc.exists) return null;
    return AdministrativeUnit.fromJson({
      ...doc.data()!,
      'id': doc.id,
    });
  }
  
  /// Add a new unit
  Future<String> addUnit(AdministrativeUnit unit) async {
    final docRef = await _firestore.collection(_collectionName).add(unit.toJson());
    return docRef.id;
  }
  
  /// Update an existing unit
  Future<void> updateUnit(String id, AdministrativeUnit unit) async {
    await _firestore.collection(_collectionName).doc(id).update(unit.toJson());
  }
  
  /// Delete a unit
  Future<void> deleteUnit(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
  
  /// Search units by name
  Stream<List<AdministrativeUnit>> searchUnits(String query) {
    return _firestore
        .collection(_collectionName)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdministrativeUnit.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }
}
