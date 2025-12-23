import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification_model.dart';
import 'package:logger/logger.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Get notifications for a specific user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  // Get all notifications (for admin)
  Stream<List<NotificationModel>> getAllNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      _logger.i('✅ Notification marked as read: $notificationId');
    } catch (e) {
      _logger.e('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      _logger.i('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      _logger.e('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'actionUrl': actionUrl,
        'metadata': metadata,
      });
      _logger.i('✅ Notification created for user: $userId');
    } catch (e) {
      _logger.e('❌ Error creating notification: $e');
      rethrow;
    }
  }

  // Create broadcast notification (for all users)
  Future<void> createBroadcastNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get all user IDs
      final usersSnapshot = await _firestore.collection('users').get();

      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'title': title,
          'message': message,
          'type': type.name,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'actionUrl': actionUrl,
          'metadata': metadata,
        });
      }

      await batch.commit();
      _logger.i('✅ Broadcast notification created for all users');
    } catch (e) {
      _logger.e('❌ Error creating broadcast notification: $e');
      rethrow;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      _logger.i('✅ Notification deleted: $notificationId');
    } catch (e) {
      _logger.e('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _logger.i('✅ All notifications deleted for user: $userId');
    } catch (e) {
      _logger.e('❌ Error deleting all notifications: $e');
      rethrow;
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      _logger.e('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // Stream unread count
  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
