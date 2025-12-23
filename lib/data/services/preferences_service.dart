import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class PreferencesService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _darkModeKey = 'dark_mode';
  static const String _languageKey = 'language';

  final Logger _logger = Logger();

  // Notifications
  Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationsEnabledKey) ?? true;
    } catch (e) {
      _logger.e('Error getting notifications enabled: $e');
      return true;
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, value);
      _logger.i('Notifications enabled set to: $value');
    } catch (e) {
      _logger.e('Error setting notifications enabled: $e');
    }
  }

  Future<bool> getEmailNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_emailNotificationsKey) ?? true;
    } catch (e) {
      _logger.e('Error getting email notifications: $e');
      return true;
    }
  }

  Future<void> setEmailNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emailNotificationsKey, value);
      _logger.i('Email notifications set to: $value');
    } catch (e) {
      _logger.e('Error setting email notifications: $e');
    }
  }

  Future<bool> getPushNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pushNotificationsKey) ?? true;
    } catch (e) {
      _logger.e('Error getting push notifications: $e');
      return true;
    }
  }

  Future<void> setPushNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pushNotificationsKey, value);
      _logger.i('Push notifications set to: $value');
    } catch (e) {
      _logger.e('Error setting push notifications: $e');
    }
  }

  // Dark mode
  Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_darkModeKey) ?? false;
    } catch (e) {
      _logger.e('Error getting dark mode: $e');
      return false;
    }
  }

  Future<void> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
      _logger.i('Dark mode set to: $value');
    } catch (e) {
      _logger.e('Error setting dark mode: $e');
    }
  }

  // Language
  Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'vi';
    } catch (e) {
      _logger.e('Error getting language: $e');
      return 'vi';
    }
  }

  Future<void> setLanguage(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, value);
      _logger.i('Language set to: $value');
    } catch (e) {
      _logger.e('Error setting language: $e');
    }
  }

  // Clear all preferences
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _logger.i('All preferences cleared');
    } catch (e) {
      _logger.e('Error clearing preferences: $e');
    }
  }
}
