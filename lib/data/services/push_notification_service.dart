import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/navigation_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received:');
  debugPrint('  Title: ${message.notification?.title}');
  debugPrint('  Body: ${message.notification?.body}');
  debugPrint('  Data: ${message.data}');
}

/// Enhanced FCM Service with local notifications support
class PushNotificationService {
  // Singleton pattern
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'nhs_dangbo_high_importance', // id
    'Thông báo quan trọng', // name
    description: 'Kênh thông báo quan trọng từ Đảng Bộ Phường Ngũ Hành Sơn',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Push Notification Service already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing Push Notification Service...');

      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
      });

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      debugPrint('✅ Push Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Push Notification Service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User declined notification permission');
      }
    } catch (e) {
      debugPrint('❌ Error requesting permission: $e');
    }
  }

  /// Initialize local notifications for showing in foreground
  Future<void> _initializeLocalNotifications() async {
    try {
      // Skip initialization on unsupported platforms (Windows, Linux, macOS in dev mode)
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        debugPrint(
            '⚠️ Local notifications not supported on ${defaultTargetPlatform.name}');
        return;
      }

      // Android settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Create Android notification channel
      final android = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);

      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
      debugPrint('💡 This is expected on Windows/Desktop during development');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from terminated state via notification
    _checkInitialMessage();
  }

  /// Handle foreground messages (show local notification)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message:');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');

    // Show local notification
    _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Skip on unsupported platforms
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        debugPrint(
            '⚠️ Skipping local notification on ${defaultTargetPlatform.name}');
        return;
      }

      final notification = message.notification;
      if (notification == null) return;

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['action'],
      );

      debugPrint('✅ Local notification shown');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    // Navigate to notifications screen
    final navigationService = NavigationService();
    navigationService.navigateToNotifications();
  }

  /// Handle message opened from background/terminated
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 App opened from notification:');
    debugPrint('  Data: ${message.data}');

    // Handle navigation based on notification data
    final navigationService = NavigationService();
    navigationService.handleNotificationAction(message.data);
  }

  /// Check if app was opened from notification in terminated state
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App opened from notification (terminated state)');
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Save FCM token to Firestore
  Future<void> saveFCMToken(String userId) async {
    try {
      if (_fcmToken == null) {
        debugPrint('⚠️ No FCM token to save');
        return;
      }

      // Save to Firestore (for app usage)
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': true,
      });

      debugPrint('✅ FCM token saved to Firestore for user: $userId');

      // ALSO save to Supabase (for Edge Function to read)
      try {
        await Supabase.instance.client.from('users').upsert({
          'id': userId,
          'fcm_token': _fcmToken,
          'fcm_token_updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ FCM token saved to Supabase for user: $userId');
      } catch (supabaseError) {
        debugPrint('⚠️ Failed to save FCM token to Supabase: $supabaseError');
        // Don't throw - Firestore save is more important
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
        'notificationsEnabled': false,
      });

      await _messaging.deleteToken();
      _fcmToken = null;

      debugPrint('✅ FCM token deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Enable notifications for user
  Future<void> enableNotifications(String userId) async {
    try {
      // Save token
      await saveFCMToken(userId);

      // Subscribe to user's personal topic
      await subscribeToTopic('user_$userId');

      // Subscribe to broadcast topic
      await subscribeToTopic('all_users');

      debugPrint('✅ Notifications enabled for user: $userId');
    } catch (e) {
      debugPrint('❌ Error enabling notifications: $e');
      rethrow;
    }
  }

  /// Disable notifications for user
  Future<void> disableNotifications(String userId) async {
    try {
      // Unsubscribe from topics
      await unsubscribeFromTopic('user_$userId');
      await unsubscribeFromTopic('all_users');

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'notificationsEnabled': false,
      });

      debugPrint('✅ Notifications disabled for user: $userId');
    } catch (e) {
      debugPrint('❌ Error disabling notifications: $e');
      rethrow;
    }
  }

  /// Send notification to all admins
  Future<void> sendNotificationToAllAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 Sending notification to all admins...');

      // Get all admin users
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      if (adminsSnapshot.docs.isEmpty) {
        debugPrint('⚠️ No admin users found with FCM tokens');
        return;
      }

      debugPrint(
          '📬 Found ${adminsSnapshot.docs.length} admin(s) to notify'); // Create notification document for each admin
      for (final adminDoc in adminsSnapshot.docs) {
        final adminId = adminDoc.id;

        // Create notification document in SUPABASE (not Firebase)
        try {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': adminId,
            'title': title,
            'message': body,
            'body': body,
            'type': 'announcement',
            'read': false,
            'metadata': data ?? {},
            'data': data ?? {},
          });
          debugPrint('✅ Notification created in Supabase for admin: $adminId');
        } catch (supabaseError) {
          debugPrint(
              '❌ Error creating notification in Supabase: $supabaseError');
        }
      }

      debugPrint(
          '✅ Notifications sent to ${adminsSnapshot.docs.length} admin(s)');
    } catch (e) {
      debugPrint('❌ Error sending notification to admins: $e');
      rethrow;
    }
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 Sending notification to user: $userId');

      // Check if user has FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        final errorMsg = 'User not found: $userId';
        debugPrint('❌ $errorMsg');
        throw Exception(errorMsg);
      }

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) {
        final errorMsg =
            'User has no FCM token: $userId. User needs to login to the app first to receive notifications.';
        debugPrint('! $errorMsg');

        // Still create notification in Supabase so user can see it when they login
        try {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': userId,
            'title': title,
            'message': body,
            'body': body,
            'type': 'info',
            'read': false,
            'metadata': data ?? {},
            'data': data ?? {},
          });
          debugPrint(
              '✅ Notification saved in Supabase (user will see when they login)');
        } catch (supabaseError) {
          debugPrint(
              '❌ Error creating notification in Supabase: $supabaseError');
        }

        // Throw error so caller knows notification was not sent via FCM
        throw Exception(errorMsg);
      } // Create notification document in SUPABASE (not Firebase)
      String? notificationId;
      try {
        final response = await Supabase.instance.client
            .from('notifications')
            .insert({
              'user_id': userId,
              'title': title,
              'message': body,
              'body': body,
              'type': 'info',
              'read': false,
              'metadata': data ?? {},
              'data': data ?? {},
            })
            .select('id')
            .single();

        notificationId = response['id'] as String?;
        debugPrint(
            '✅ Notification created in Supabase for user: $userId (ID: $notificationId)');
      } catch (supabaseError) {
        debugPrint('❌ Error creating notification in Supabase: $supabaseError');
        rethrow;
      } // Call Edge Function directly to send FCM (don't rely on webhook)
      try {
        debugPrint('📤 Calling Edge Function to send FCM notification...');
        debugPrint('   FCM Token: ${fcmToken.substring(0, 30)}...');

        final response = await Supabase.instance.client.functions.invoke(
          'send-fcm-notification',
          body: {
            'type': 'INSERT',
            'record': {
              'id': notificationId ?? '',
              'user_id': userId,
              'title': title,
              'message': body,
              'body': body,
              'type': 'info',
              'fcm_token':
                  fcmToken, // Include FCM token so Edge Function doesn't need to fetch it
            },
          },
        );

        if (response.status == 200) {
          debugPrint('✅ FCM notification sent successfully via Edge Function');
          debugPrint('   Response: ${response.data}');
        } else {
          debugPrint('⚠️ Edge Function returned status: ${response.status}');
          debugPrint('   Response: ${response.data}');
        }
      } catch (edgeFunctionError) {
        debugPrint('❌ Error calling Edge Function: $edgeFunctionError');
        debugPrint('⚠️ Notification saved in Supabase but FCM not sent');
        // Don't rethrow - notification is saved, FCM failure is not critical
      }

      debugPrint('✅ Sent notification to user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification to user: $e');
      rethrow;
    }
  }
}
