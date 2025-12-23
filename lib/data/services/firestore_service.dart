import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(); // Collections
  static const String _usersCollection = 'users';
  static const String _adminConfigCollection =
      'system_settings'; // Changed from 'config'

  // HARDCODED ADMIN EMAILS - These emails are ALWAYS admin
  static const List<String> _hardcodedAdminEmails = [
    'admin@gmail.com', // Primary hardcoded admin
  ];

  // Default admin emails (can be overridden in Firestore)
  static const List<String> _defaultAdminEmails = [
    'admin@nhs.vn',
    'admin@gmail.com',
    'quanly@nhs.vn',
  ];

  /// Save or update user in Firestore
  Future<void> saveUser(AppUser user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.uid).set(
            user.toJson(),
            SetOptions(merge: true),
          );
      _logger.i('User saved to Firestore: ${user.email}');
    } catch (e) {
      // Nếu lỗi permission, chỉ log warning, không throw error
      _logger.w('Cannot save user to Firestore: $e');
      // Don't rethrow - cho phép app hoạt động với local storage
    }
  }

  /// Get user from Firestore
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.w('Cannot get user from Firestore: $e');
      return null;
    }
  }

  /// Check if email is admin (hardcoded + Firestore config)
  Future<bool> isAdminEmail(String email) async {
    final emailLower = email.toLowerCase().trim();

    // HARDCODED ADMIN - Always returns true for specific email
    if (_hardcodedAdminEmails.contains(emailLower)) {
      _logger.i('✅ Hardcoded admin detected: $email');
      return true;
    }

    // Check Firestore config for additional admins
    try {
      final doc = await _firestore
          .collection(_adminConfigCollection)
          .doc('admin_emails')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final List<dynamic> adminEmails = data?['emails'] ?? [];
        final isAdmin =
            adminEmails.any((e) => e.toString().toLowerCase() == emailLower);
        if (isAdmin) {
          _logger.i('✅ Firestore admin detected: $email');
        }
        return isAdmin;
      }

      // Fallback to default admin emails if not found in Firestore
      _logger.w('Admin config not found in Firestore, using defaults');
      return _defaultAdminEmails.contains(emailLower);
    } catch (e) {
      // Nếu lỗi permission, chỉ check local defaults
      _logger.w(
          'Cannot check admin from Firestore (${e.toString()}), checking defaults only');
      return _defaultAdminEmails.contains(emailLower);
    }
  }

  /// Get list of admin emails from Firestore
  Future<List<String>> getAdminEmails() async {
    try {
      final doc = await _firestore
          .collection(_adminConfigCollection)
          .doc('admin_emails')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final List<dynamic> adminEmails = data?['emails'] ?? [];
        return adminEmails.map((e) => e.toString()).toList();
      }

      return _defaultAdminEmails;
    } catch (e) {
      _logger.e('Error getting admin emails: $e');
      return _defaultAdminEmails;
    }
  }

  /// Add admin email to Firestore
  Future<void> addAdminEmail(String email) async {
    try {
      await _firestore
          .collection(_adminConfigCollection)
          .doc('admin_emails')
          .set({
        'emails': FieldValue.arrayUnion([email.toLowerCase()]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.i('✅ Admin email added: $email');
    } catch (e) {
      _logger.w('Cannot add admin email to Firestore: $e');
      // Don't throw - allow local operation
    }
  }

  /// Remove admin email from Firestore
  Future<void> removeAdminEmail(String email) async {
    try {
      await _firestore
          .collection(_adminConfigCollection)
          .doc('admin_emails')
          .set({
        'emails': FieldValue.arrayRemove([email.toLowerCase()]),
      }, SetOptions(merge: true));

      _logger.i('Admin email removed: $email');
    } catch (e) {
      _logger.e('Error removing admin email: $e');
      rethrow;
    }
  }

  /// Initialize admin config with default emails
  Future<void> initializeAdminConfig() async {
    try {
      final doc = await _firestore
          .collection(_adminConfigCollection)
          .doc('admin_emails')
          .get();

      if (!doc.exists) {
        await _firestore
            .collection(_adminConfigCollection)
            .doc('admin_emails')
            .set({
          'emails': _defaultAdminEmails,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _logger.i('✅ Admin config initialized with default emails');
      } else {
        _logger.i('ℹ️ Admin config already exists');
      }
    } catch (e) {
      _logger.e(
          '❌ Error initializing admin config: $e'); // Don't rethrow - this is optional initialization
    }
  }

  /// Auto-promote first registered user to admin (helpful for initial setup)
  Future<void> autoPromoteFirstUser(String email) async {
    try {
      // Check if any users exist
      final usersSnapshot =
          await _firestore.collection(_usersCollection).limit(1).get();

      // If this is the first user, make them admin automatically
      if (usersSnapshot.docs.isEmpty) {
        _logger.i('🌟 First user detected! Auto-promoting to admin: $email');
        await addAdminEmail(email);
      }
    } catch (e) {
      _logger.w('Cannot check first user status: $e');
    }
  }

  /// Get user role
  Future<UserRole> getUserRole(String email) async {
    final isAdmin = await isAdminEmail(email);
    return isAdmin ? UserRole.admin : UserRole.user;
  }

  /// Update user role
  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': role.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i('User role updated: $uid -> $role');
    } catch (e) {
      _logger.e('Error updating user role: $e');
      rethrow;
    }
  }

  /// Delete user from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      _logger.i('User deleted from Firestore: $uid');
    } catch (e) {
      _logger.e('Error deleting user from Firestore: $e');
      rethrow;
    }
  }

  /// Get all users (for admin)
  Stream<List<AppUser>> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList(),
        );
  }

  /// Search users by email
  Future<List<AppUser>> searchUsersByEmail(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
    } catch (e) {
      _logger.e('Error searching users: $e');
      return [];
    }
  }
}
