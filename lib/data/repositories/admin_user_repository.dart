import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/app_user.dart';

class AdminUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convert AppUser to User entity
  User _appUserToUser(AppUser appUser, Map<String, dynamic>? extraData) {
    return User(
      id: appUser.uid,
      name: appUser.displayName ?? 'Không rõ',
      email: appUser.email,
      phone: extraData?['phone'] as String?,
      role: appUser.role.name, // 'admin', 'user', 'moderator'
      createdAt: appUser.createdAt ?? DateTime.now(),
      isBlocked: extraData?['isBlocked'] as bool? ?? false,
      isDeleted: extraData?['isDeleted'] as bool? ?? false,
    );
  }

  /// Stream all users with real-time updates (excluding deleted users)
  Stream<List<User>> streamAllUsers() {
    try {
      return _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.where((doc) {
          final data = doc.data();
          final isDeleted = data['isDeleted'] as bool? ?? false;
          return !isDeleted; // Filter out deleted users
        }).map((doc) {
          try {
            final data = doc.data();
            final appUser = AppUser.fromJson(data);
            return _appUserToUser(appUser, data);
          } catch (e) {
            print('❌ Error parsing user ${doc.id}: $e');
            final data = doc.data();
            // Return a default user for invalid data
            return User(
              id: doc.id,
              name: data['displayName']?.toString() ?? 'Lỗi dữ liệu',
              email: data['email']?.toString() ?? 'unknown',
              role: data['role']?.toString() ?? 'user',
              createdAt: DateTime.now(),
              isBlocked: data['isBlocked'] as bool? ?? false,
              isDeleted: data['isDeleted'] as bool? ?? false,
            );
          }
        }).toList();
      });
    } catch (e) {
      print('❌ Error streaming all users: $e');
      return Stream.value([]);
    }
  }

  /// Get all users (one-time fetch, excluding deleted)
  Future<List<User>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.where((doc) {
        final data = doc.data();
        final isDeleted = data['isDeleted'] as bool? ?? false;
        return !isDeleted; // Filter out deleted users
      }).map((doc) {
        try {
          final data = doc.data();
          final appUser = AppUser.fromJson(data);
          return _appUserToUser(appUser, data);
        } catch (e) {
          print('❌ Error parsing user ${doc.id}: $e');
          final data = doc.data();
          // Return a default user for invalid data
          return User(
            id: doc.id,
            name: data['displayName']?.toString() ?? 'Lỗi dữ liệu',
            email: data['email']?.toString() ?? 'unknown',
            role: data['role']?.toString() ?? 'user',
            createdAt: DateTime.now(),
            isBlocked: data['isBlocked'] as bool? ?? false,
            isDeleted: data['isDeleted'] as bool? ?? false,
          );
        }
      }).toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final appUser = AppUser.fromJson(data);
      return _appUserToUser(appUser, data);
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating user role: $e');
      rethrow;
    }
  }

  /// Block user
  Future<void> blockUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': true,
        'blockedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock user
  Future<void> unblockUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': false,
        'blockedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error unblocking user: $e');
      rethrow;
    }
  }

  /// Delete user (soft delete - mark as deleted)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  /// Permanently delete user from Firestore and Firebase Auth
  Future<void> permanentlyDeleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();
      // Note: Firebase Auth user deletion requires admin SDK or user's own credential
      // For complete deletion, use Firebase Admin SDK in backend or delete via Firebase Console
    } catch (e) {
      print('❌ Error permanently deleting user: $e');
      rethrow;
    }
  }

  /// Create new user with email and password (Admin only)
  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    String role = 'user',
    bool skipEmailVerification = false,
  }) async {
    try {
      // Create user document in Firestore with pending status
      // The actual Firebase Auth account should be created via Firebase Admin SDK
      // or user self-registration for security reasons
      final userRef = _firestore.collection('users').doc();

      await userRef.set({
        'uid': userRef.id,
        'email': email.toLowerCase(),
        'displayName': displayName,
        'role': role,
        'isBlocked': false,
        'isDeleted': false,
        'emailVerified': skipEmailVerification,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdBy': 'admin',
        'pendingPassword':
            password, // Temporary - should be removed after first login
        'requiresPasswordChange': true,
      });

      print('✅ User created in Firestore: $email');
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
    }
  }

  /// Update user information
  Future<void> updateUser(
    String userId, {
    String? name,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['displayName'] = name;
      if (phone != null) updates['phone'] = phone;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  /// Stream statistics with real-time updates
  Stream<Map<String, dynamic>> streamStatistics() {
    try {
      // Combine users and feedbacks streams
      return _firestore
          .collection('feedbacks')
          .snapshots()
          .asyncMap((feedbacksSnapshot) async {
        // Get users count (we need to fetch this once per feedback update)
        final usersSnapshot = await _firestore.collection('users').get();

        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

        final newUsersThisWeek = usersSnapshot.docs.where((doc) {
          try {
            final data = doc.data();
            final createdAtStr = data['createdAt'] as String?;
            if (createdAtStr == null) return false;
            final createdAt = DateTime.parse(createdAtStr);
            return createdAt.isAfter(startOfWeek);
          } catch (e) {
            return false;
          }
        }).length;

        final newFeedbacksToday = feedbacksSnapshot.docs.where((doc) {
          try {
            final data = doc.data();
            final createdAtStr = data['createdAt'] as String?;
            if (createdAtStr == null) return false;
            final createdAt = DateTime.parse(createdAtStr);
            return createdAt.year == now.year &&
                createdAt.month == now.month &&
                createdAt.day == now.day;
          } catch (e) {
            return false;
          }
        }).length;

        final pendingFeedbacks = feedbacksSnapshot.docs
            .where((doc) => doc.data()['status'] == 'Đã nhận')
            .length;

        final processingFeedbacks = feedbacksSnapshot.docs
            .where((doc) => doc.data()['status'] == 'Đang xử lý')
            .length;

        final completedFeedbacks = feedbacksSnapshot.docs
            .where((doc) => doc.data()['status'] == 'Đã hoàn thành')
            .length;

        return {
          'totalUsers': usersSnapshot.docs.length,
          'totalFeedbacks': feedbacksSnapshot.docs.length,
          'newUsersThisWeek': newUsersThisWeek,
          'newFeedbacksToday': newFeedbacksToday,
          'pendingFeedbacks': pendingFeedbacks,
          'processingFeedbacks': processingFeedbacks,
          'completedFeedbacks': completedFeedbacks,
        };
      });
    } catch (e) {
      print('❌ Error streaming statistics: $e');
      return Stream.value({});
    }
  }

  /// Get statistics (one-time fetch, kept for backward compatibility)
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final feedbacksSnapshot = await _firestore.collection('feedbacks').get();
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      final newUsersThisWeek = usersSnapshot.docs.where((doc) {
        try {
          final data = doc.data();
          final createdAtStr = data['createdAt'] as String?;
          if (createdAtStr == null) return false;
          final createdAt = DateTime.parse(createdAtStr);
          return createdAt.isAfter(startOfWeek);
        } catch (e) {
          return false;
        }
      }).length;

      final newFeedbacksToday = feedbacksSnapshot.docs.where((doc) {
        try {
          final data = doc.data();
          final createdAtStr = data['createdAt'] as String?;
          if (createdAtStr == null) return false;
          final createdAt = DateTime.parse(createdAtStr);
          return createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        } catch (e) {
          return false;
        }
      }).length;

      final pendingFeedbacks = feedbacksSnapshot.docs
          .where((doc) => doc.data()['status'] == 'Đã nhận')
          .length;

      final processingFeedbacks = feedbacksSnapshot.docs
          .where((doc) => doc.data()['status'] == 'Đang xử lý')
          .length;

      final completedFeedbacks = feedbacksSnapshot.docs
          .where((doc) => doc.data()['status'] == 'Đã hoàn thành')
          .length;

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalFeedbacks': feedbacksSnapshot.docs.length,
        'newUsersThisWeek': newUsersThisWeek,
        'newFeedbacksToday': newFeedbacksToday,
        'pendingFeedbacks': pendingFeedbacks,
        'processingFeedbacks': processingFeedbacks,
        'completedFeedbacks': completedFeedbacks,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }
}
