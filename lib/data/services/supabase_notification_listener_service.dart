import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to listen for new notifications from Supabase and show local notifications
/// Replaces Firebase Firestore listener
class SupabaseNotificationListenerService {
  static final SupabaseNotificationListenerService _instance =
      SupabaseNotificationListenerService._internal();
  factory SupabaseNotificationListenerService() => _instance;
  SupabaseNotificationListenerService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _notificationSubscription;
  bool _isListening = false;
  final Set<String> _processedNotificationIds = {};

  // Lazy getter
  SupabaseClient get _client {
    if (!Supabase.instance.isInitialized) {
      throw Exception('❌ Supabase chưa được khởi tạo');
    }
    return Supabase.instance.client;
  }

  /// Start listening for new notifications
  Future<void> startListening(String userId) async {
    if (_isListening) {
      debugPrint('⚠️ Notification listener already running');
      return;
    }

    try {
      debugPrint(
          '🎧 Starting Supabase notification listener for user: $userId');

      // Listen to notifications table for this user
      // Note: Filtering happens in the listener callback since Supabase stream
      // doesn't support .eq() after .stream()
      _notificationSubscription = _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((List<Map<String, dynamic>> data) {
            // Filter for this user and unread notifications
            final filtered = data
                .where((notification) {
                  return notification['user_id'] == userId &&
                      notification['read'] == false;
                })
                .take(10)
                .toList();

            if (filtered.isNotEmpty) {
              _handleNotificationSnapshot(filtered);
            }
          });

      _isListening = true;
      debugPrint('✅ Supabase notification listener started');
    } catch (e) {
      debugPrint('❌ Error starting notification listener: $e');
    }
  }

  /// Handle notification snapshot changes
  void _handleNotificationSnapshot(List<Map<String, dynamic>> data) {
    for (final notification in data) {
      final notificationId = notification['id'] as String;

      // Skip if already processed
      if (_processedNotificationIds.contains(notificationId)) {
        continue;
      }

      // Mark as processed
      _processedNotificationIds.add(notificationId);

      // Show local notification
      _showLocalNotification(
        notificationId: notificationId,
        title: notification['title'] ?? 'Thông báo mới',
        body: notification['message'] ?? notification['body'] ?? '',
        payload: notification['type'] ?? 'info',
      );

      debugPrint('📬 New notification: ${notification['title']}');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String notificationId,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      // Skip on unsupported platforms
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        debugPrint(
            '⚠️ Skipping local notification on ${defaultTargetPlatform.name}');
        return;
      }

      await _localNotifications.show(
        notificationId.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nhs_dangbo_high_importance',
            'Thông báo quan trọng',
            channelDescription:
                'Kênh thông báo quan trọng từ Đảng Bộ Phường Ngũ Hành Sơn',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      debugPrint('✅ Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Stop listening
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isListening = false;
    _processedNotificationIds.clear();
    debugPrint('🛑 Notification listener stopped');
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);
      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }
}
