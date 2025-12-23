import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Request notification permissions
      final permission = await _requestPermission();
      if (!permission) {
        _logger.w('Notification permission denied');
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      _logger.i('📱 FCM Token: $_fcmToken');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _logger.i('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // TODO: Send new token to server
      });

      // Set foreground notification presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      _logger.i('✅ FCM initialized successfully');
    } catch (e) {
      _logger.e('❌ Error initializing FCM: $e');
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermission() async {
    try {
      if (Platform.isIOS) {
        // iOS requires explicit permission request
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      } else if (Platform.isAndroid) {
        // Android 13+ requires notification permission
        if (await Permission.notification.isDenied) {
          final status = await Permission.notification.request();
          return status.isGranted;
        }
        return true;
      }
      return true;
    } catch (e) {
      _logger.e('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Setup message listeners
  void setupMessageListeners({
    Function(RemoteMessage)? onMessage,
    Function(RemoteMessage)? onMessageOpenedApp,
    Function(RemoteMessage)? onBackgroundMessage,
  }) {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('📩 Foreground message received: ${message.messageId}');
      _logger.i('Title: ${message.notification?.title}');
      _logger.i('Body: ${message.notification?.body}');
      _logger.i('Data: ${message.data}');

      onMessage?.call(message);
    });

    // Handle when user taps notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('🔔 Notification tapped (background): ${message.messageId}');
      _logger.i('Data: ${message.data}');

      onMessageOpenedApp?.call(message);
    });

    // Check if app was opened from a terminated state via notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _logger.i('🚀 App opened from notification: ${message.messageId}');
        _logger.i('Data: ${message.data}');

        onMessageOpenedApp?.call(message);
      }
    });
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _logger.i('✅ Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _logger.i('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      _logger.i('✅ FCM token deleted');
    } catch (e) {
      _logger.e('❌ Error deleting FCM token: $e');
    }
  }

  /// Show local notification (for foreground messages)
  void showLocalNotification(RemoteMessage message) {
    // TODO: Implement local notification using flutter_local_notifications
    // This would show a notification even when app is in foreground
    _logger.i('Show local notification: ${message.notification?.title}');
  }
}
