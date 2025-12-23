import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification_model.dart';

/// Service for handling notifications using Supabase
/// Replaces Firebase Firestore for notifications
class SupabaseNotificationService {
  // Lazy getter - only access client when needed
  SupabaseClient get _client {
    if (!Supabase.instance.isInitialized) {
      throw Exception(
          '❌ Supabase chưa được khởi tạo. Vui lòng kiểm tra main.dart');
    }
    return Supabase.instance.client;
  }

  /// Get notifications for a specific user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          // Filter by user_id in the callback
          final filtered =
              data.where((item) => item['user_id'] == userId).toList();
          // Limit to 50 most recent
          final limited = filtered.take(50).toList();
          return limited.map((json) {
            // Convert snake_case to camelCase for compatibility
            final converted = _convertFromSupabase(json);
            return NotificationModel.fromJson(converted);
          }).toList();
        });
  }

  /// Get all notifications (for admin)
  Stream<List<NotificationModel>> getAllNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map((List<Map<String, dynamic>> data) {
          return data.map((json) {
            final converted = _convertFromSupabase(json);
            return NotificationModel.fromJson(converted);
          }).toList();
        });
  }

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'body': message, // Alias for compatibility
        'type': type.name,
        'read': false,
        'action_url': actionUrl,
        'metadata': metadata,
        'data': metadata, // Alias for compatibility
      });
      debugPrint('✅ Notification created for user: $userId');
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      rethrow;
    }
  }

  /// Create broadcast notification (for all users)
  Future<void> createBroadcastNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notifications = userIds
          .map((userId) => {
                'user_id': userId,
                'title': title,
                'message': message,
                'body': message,
                'type': type.name,
                'read': false,
                'action_url': actionUrl,
                'metadata': metadata,
                'data': metadata,
              })
          .toList();

      await _client.from('notifications').insert(notifications);
      debugPrint(
          '✅ Broadcast notification created for ${userIds.length} users');
    } catch (e) {
      debugPrint('❌ Error creating broadcast notification: $e');
      rethrow;
    }
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
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
      debugPrint('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
      debugPrint('✅ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      await _client.from('notifications').delete().eq('user_id', userId);
      debugPrint('✅ All notifications deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
      rethrow;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Stream unread count
  Stream<int> streamUnreadCount(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id']).map((List<Map<String, dynamic>> data) {
      // Filter by user_id and unread in memory
      return data
          .where((item) => item['user_id'] == userId && item['read'] == false)
          .length;
    });
  }

  /// Convert Supabase response (snake_case) to Firebase format (camelCase)
  Map<String, dynamic> _convertFromSupabase(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'userId': json['user_id'],
      'title': json['title'],
      'message': json['message'] ?? json['body'],
      'body': json['body'] ?? json['message'],
      'type': json['type'],
      'createdAt': json['created_at'],
      'read': json['read'],
      'readAt': json['read_at'],
      'actionUrl': json['action_url'],
      'metadata': json['metadata'] ?? json['data'],
      'data': json['data'] ?? json['metadata'],
    };
  }
}
