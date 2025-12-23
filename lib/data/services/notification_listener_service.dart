import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to listen for new notifications from Firestore and show local notifications
class NotificationListenerService {
  static final NotificationListenerService _instance =
      NotificationListenerService._internal();
  factory NotificationListenerService() => _instance;
  NotificationListenerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isListening = false;
  final Set<String> _processedNotificationIds = {};

  /// Start listening for new notifications
  Future<void> startListening(String userId) async {
    if (_isListening) {
      debugPrint('⚠️ Notification listener already running');
      return;
    }

    try {
      debugPrint('🎧 Starting notification listener for user: $userId');

      // Listen to notifications collection for this user
      _notificationSubscription = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()
          .listen((snapshot) {
        _handleNotificationSnapshot(snapshot);
      });

      _isListening = true;
      debugPrint('✅ Notification listener started');
    } catch (e) {
      debugPrint('❌ Error starting notification listener: $e');
    }
  }

  /// Handle notification snapshot changes
  void _handleNotificationSnapshot(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final doc = change.doc;
        final notificationId = doc.id;

        // Skip if already processed
        if (_processedNotificationIds.contains(notificationId)) {
          continue;
        }

        // Mark as processed
        _processedNotificationIds.add(notificationId);

        // Show local notification
        final data = doc.data() as Map<String, dynamic>;
        _showLocalNotification(
          notificationId: notificationId,
          title: data['title'] ?? 'Thông báo mới',
          body: data['body'] ?? '',
          payload: data['data']?['type'] ?? '',
        );

        debugPrint('📬 New notification: ${data['title']}');
      }
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
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }
}
