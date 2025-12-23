import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsCollection = 'system_settings';

  // ==================== NOTIFICATION SETTINGS ====================

  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final doc = await _firestore
          .collection(_settingsCollection)
          .doc('notifications')
          .get();

      if (doc.exists) {
        return doc.data() ?? _defaultNotificationSettings();
      }
      return _defaultNotificationSettings();
    } catch (e) {
      print('❌ Error getting notification settings: $e');
      return _defaultNotificationSettings();
    }
  }

  Future<void> updateNotificationSettings({
    required bool pushEnabled,
    required bool emailEnabled,
    required bool smsEnabled,
  }) async {
    try {
      await _firestore
          .collection(_settingsCollection)
          .doc('notifications')
          .set({
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Notification settings saved');
    } catch (e) {
      print('❌ Error saving notification settings: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _defaultNotificationSettings() {
    return {
      'pushEnabled': true,
      'emailEnabled': true,
      'smsEnabled': false,
    };
  }

  // ==================== SECURITY SETTINGS ====================

  Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      final doc = await _firestore
          .collection(_settingsCollection)
          .doc('security')
          .get();

      if (doc.exists) {
        return doc.data() ?? _defaultSecuritySettings();
      }
      return _defaultSecuritySettings();
    } catch (e) {
      print('❌ Error getting security settings: $e');
      return _defaultSecuritySettings();
    }
  }

  Future<void> updateSecuritySettings({
    required bool twoFactorAuth,
    required bool requireEmailVerification,
    required int sessionTimeout,
  }) async {
    try {
      await _firestore.collection(_settingsCollection).doc('security').set({
        'twoFactorAuth': twoFactorAuth,
        'requireEmailVerification': requireEmailVerification,
        'sessionTimeout': sessionTimeout,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Security settings saved');
    } catch (e) {
      print('❌ Error saving security settings: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _defaultSecuritySettings() {
    return {
      'twoFactorAuth': false,
      'requireEmailVerification': true,
      'sessionTimeout': 30,
    };
  }

  // ==================== BACKUP SETTINGS ====================

  Future<Map<String, dynamic>> getBackupSettings() async {
    try {
      final doc =
          await _firestore.collection(_settingsCollection).doc('backup').get();

      if (doc.exists) {
        return doc.data() ?? _defaultBackupSettings();
      }
      return _defaultBackupSettings();
    } catch (e) {
      print('❌ Error getting backup settings: $e');
      return _defaultBackupSettings();
    }
  }

  Future<void> updateBackupSettings({
    required bool autoBackup,
    required String backupFrequency,
  }) async {
    try {
      await _firestore.collection(_settingsCollection).doc('backup').set({
        'autoBackup': autoBackup,
        'backupFrequency': backupFrequency,
        'lastBackup': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Backup settings saved');
    } catch (e) {
      print('❌ Error saving backup settings: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _defaultBackupSettings() {
    return {
      'autoBackup': true,
      'backupFrequency': 'daily',
    };
  }

  // ==================== EMAIL TEMPLATE SETTINGS ====================

  Future<List<Map<String, dynamic>>> getEmailTemplates() async {
    try {
      final querySnapshot = await _firestore
          .collection(_settingsCollection)
          .doc('email_templates')
          .collection('templates')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return _defaultEmailTemplates();
      }

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting email templates: $e');
      return _defaultEmailTemplates();
    }
  }

  Future<void> updateEmailTemplate({
    required String type,
    required String name,
    required String subject,
    required String body,
  }) async {
    try {
      await _firestore
          .collection(_settingsCollection)
          .doc('email_templates')
          .collection('templates')
          .doc(type)
          .set({
        'type': type,
        'name': name,
        'subject': subject,
        'body': body,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Email template saved');
    } catch (e) {
      print('❌ Error saving email template: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _defaultEmailTemplates() {
    return [
      {
        'name': 'Chào mừng người dùng mới',
        'subject': 'Chào mừng đến với NHS App',
        'type': 'welcome',
        'body': 'Xin chào {userName},\n\nChào mừng bạn đến với NHS App!',
      },
      {
        'name': 'Xác nhận email',
        'subject': 'Xác nhận địa chỉ email',
        'type': 'verification',
        'body': 'Xin chào {userName},\n\nVui lòng xác nhận email của bạn.',
      },
      {
        'name': 'Cập nhật phản ánh',
        'subject': 'Phản ánh của bạn đã được cập nhật',
        'type': 'feedback_update',
        'body': 'Phản ánh "{feedbackTitle}" đã được cập nhật: {status}',
      },
      {
        'name': 'Phản ánh hoàn tất',
        'subject': 'Phản ánh đã được xử lý xong',
        'type': 'feedback_completed',
        'body': 'Phản ánh "{feedbackTitle}" đã được xử lý hoàn tất.',
      },
    ];
  }

  // ==================== THEME SETTINGS ====================

  Future<Map<String, dynamic>> getThemeSettings() async {
    try {
      final doc =
          await _firestore.collection(_settingsCollection).doc('theme').get();

      if (doc.exists) {
        return doc.data() ?? _defaultThemeSettings();
      }
      return _defaultThemeSettings();
    } catch (e) {
      print('❌ Error getting theme settings: $e');
      return _defaultThemeSettings();
    }
  }

  Future<void> updateThemeSettings({
    required bool darkMode,
    required int primaryColorValue,
    String? logoUrl,
  }) async {
    try {
      await _firestore.collection(_settingsCollection).doc('theme').set({
        'darkMode': darkMode,
        'primaryColorValue': primaryColorValue,
        'logoUrl': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Theme settings saved');
    } catch (e) {
      print('❌ Error saving theme settings: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _defaultThemeSettings() {
    return {
      'darkMode': false,
      'primaryColorValue': 0xFFD32F2F, // Colors.red.shade700
      'logoUrl': null,
    };
  }

  // ==================== GET ALL SETTINGS ====================

  Future<Map<String, dynamic>> getAllSettings() async {
    try {
      final notifications = await getNotificationSettings();
      final security = await getSecuritySettings();
      final backup = await getBackupSettings();
      final theme = await getThemeSettings();

      return {
        'notifications': notifications,
        'security': security,
        'backup': backup,
        'theme': theme,
      };
    } catch (e) {
      print('❌ Error getting all settings: $e');
      return {};
    }
  }
}
