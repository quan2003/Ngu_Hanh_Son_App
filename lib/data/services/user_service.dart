import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../domain/entities/app_user.dart';
import 'package:logger/logger.dart';

class UserService {
  static const String _userKey = 'current_user';
  static const String _adminEmailsKey = 'admin_emails';
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // HARDCODED ADMIN EMAILS - These emails are ALWAYS admin
  static const List<String> hardcodedAdminEmails = [
    'admin@gmail.com', // Primary hardcoded admin
  ];

  // Default admin emails (can be overridden locally)
  static const List<String> defaultAdminEmails = [
    'admin@nhs.vn',
    'admin@gmail.com',
    'quanly@nhs.vn',
  ];

  // Save user data locally
  Future<void> saveUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(_userKey, userJson);
      _logger.i('User saved: ${user.email}');
    } catch (e) {
      _logger.e('Error saving user: $e');
    }
  }

  // Get saved user
  Future<AppUser?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        return AppUser.fromJson(userData);
      }
    } catch (e) {
      _logger.e('Error getting saved user: $e');
    }
    return null;
  }

  // Clear user data
  Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _logger.i('User data cleared');
    } catch (e) {
      _logger.e('Error clearing user: $e');
    }
  }

  // Check if email is admin
  Future<bool> isAdminEmail(String email) async {
    final emailLower = email.toLowerCase().trim();

    // HARDCODED ADMIN - Always returns true
    if (hardcodedAdminEmails.contains(emailLower)) {
      _logger.i('✅ Hardcoded admin detected: $email');
      return true;
    }

    // Check Firebase first
    try {
      final doc = await _firestore
          .collection('system_settings')
          .doc('admin_emails')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final List<dynamic> adminEmails = data?['emails'] ?? [];
        final isAdmin =
            adminEmails.any((e) => e.toString().toLowerCase() == emailLower);
        if (isAdmin) {
          _logger.i('✅ Firebase admin detected: $email');
          return true;
        }
      }
    } catch (e) {
      _logger.e('Error checking Firebase admin: $e');
    }

    // Fallback to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminEmails =
          prefs.getStringList(_adminEmailsKey) ?? defaultAdminEmails;
      return adminEmails.any((e) => e.toLowerCase() == emailLower);
    } catch (e) {
      _logger.e('Error checking admin email: $e');
      return defaultAdminEmails.any((e) => e.toLowerCase() == emailLower);
    }
  }

  // Add admin email to Firebase
  Future<void> addAdminEmail(String email) async {
    final emailLower = email.toLowerCase().trim();

    try {
      // Update Firebase
      final docRef =
          _firestore.collection('system_settings').doc('admin_emails');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        List<String> adminEmails;
        if (doc.exists) {
          final data = doc.data();
          adminEmails =
              List<String>.from(data?['emails'] ?? defaultAdminEmails);
        } else {
          adminEmails = List<String>.from(defaultAdminEmails);
        }

        if (!adminEmails.contains(emailLower)) {
          adminEmails.add(emailLower);
          transaction.set(
              docRef,
              {
                'emails': adminEmails,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        }
      });

      // Also update local storage as cache
      final prefs = await SharedPreferences.getInstance();
      final adminEmails = prefs.getStringList(_adminEmailsKey) ??
          List<String>.from(defaultAdminEmails);
      if (!adminEmails.contains(emailLower)) {
        adminEmails.add(emailLower);
        await prefs.setStringList(_adminEmailsKey, adminEmails);
      }

      _logger.i('✅ Admin email added to Firebase: $email');
    } catch (e) {
      _logger.e('❌ Error adding admin email: $e');
      rethrow;
    }
  }

  // Remove admin email from Firebase
  Future<void> removeAdminEmail(String email) async {
    final emailLower = email.toLowerCase().trim();

    // Prevent removing hardcoded admins
    if (hardcodedAdminEmails.contains(emailLower) ||
        defaultAdminEmails.contains(emailLower)) {
      throw Exception('Cannot remove default admin emails');
    }

    try {
      // Update Firebase
      final docRef =
          _firestore.collection('system_settings').doc('admin_emails');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          final data = doc.data();
          List<String> adminEmails = List<String>.from(data?['emails'] ?? []);
          adminEmails.remove(emailLower);

          transaction.update(docRef, {
            'emails': adminEmails,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Also update local storage
      final prefs = await SharedPreferences.getInstance();
      final adminEmails = prefs.getStringList(_adminEmailsKey) ??
          List<String>.from(defaultAdminEmails);
      adminEmails.remove(emailLower);
      await prefs.setStringList(_adminEmailsKey, adminEmails);

      _logger.i('✅ Admin email removed from Firebase: $email');
    } catch (e) {
      _logger.e('❌ Error removing admin email: $e');
      rethrow;
    }
  }

  // Get all admin emails from Firebase
  Future<List<String>> getAdminEmails() async {
    try {
      final doc = await _firestore
          .collection('system_settings')
          .doc('admin_emails')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final List<dynamic> emails = data?['emails'] ?? defaultAdminEmails;
        return emails.map((e) => e.toString()).toList();
      }

      // If document doesn't exist, create it with defaults
      await _firestore.collection('system_settings').doc('admin_emails').set({
        'emails': defaultAdminEmails,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return List<String>.from(defaultAdminEmails);
    } catch (e) {
      _logger.e('❌ Error getting admin emails from Firebase: $e');

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_adminEmailsKey) ?? defaultAdminEmails;
    }
  }

  // Determine user role based on email
  Future<UserRole> getUserRole(String email) async {
    final isAdmin = await isAdminEmail(email);
    return isAdmin ? UserRole.admin : UserRole.user;
  }
}
