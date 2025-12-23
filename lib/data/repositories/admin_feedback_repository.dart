import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/feedback.dart' as entity;
import '../services/push_notification_service.dart';

class AdminFeedbackRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService _notificationService =
      PushNotificationService();

  /// Stream all feedbacks with real-time updates
  Stream<List<entity.Feedback>> streamAllFeedbacks() {
    try {
      return _firestore
          .collection('feedbacks')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return entity.Feedback.fromJson(doc.data());
        }).toList();
      });
    } catch (e) {
      print('❌ Error streaming all feedbacks: $e');
      return Stream.value([]);
    }
  }

  /// Get all feedbacks (one-time fetch)
  Future<List<entity.Feedback>> getAllFeedbacks() async {
    try {
      final querySnapshot = await _firestore
          .collection('feedbacks')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return entity.Feedback.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error getting all feedbacks: $e');
      return [];
    }
  }

  /// Update feedback status
  Future<void> updateFeedbackStatus(String feedbackId, String status) async {
    try {
      // Get feedback to find the owner
      final feedbackDoc =
          await _firestore.collection('feedbacks').doc(feedbackId).get();
      if (!feedbackDoc.exists) {
        throw Exception('Feedback not found');
      }

      final feedback = entity.Feedback.fromJson(feedbackDoc.data()!);
      final userId = feedback.userId;

      // Update status
      await _firestore.collection('feedbacks').doc(feedbackId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Send notification to user
      String notificationTitle = '📋 Cập nhật trạng thái phản ánh';
      String notificationBody = '';

      switch (status) {
        case 'Đang xử lý':
          notificationBody = 'Phản ánh "${feedback.title}" đang được xử lý';
          break;
        case 'Đã hoàn thành':
          notificationBody =
              'Phản ánh "${feedback.title}" đã được hoàn thành ✅';
          break;
        default:
          notificationBody =
              'Trạng thái phản ánh "${feedback.title}" đã được cập nhật';
      }

      try {
        await _notificationService.sendNotificationToUser(
          userId: userId,
          title: notificationTitle,
          body: notificationBody,
          data: {
            'type': 'feedback_status_update',
            'feedbackId': feedbackId,
            'status': status,
          },
        );
        print('✅ Sent notification to user: $userId');
      } catch (e) {
        print('⚠️ Failed to send notification to user: $e');
        // Don't throw - notification failure shouldn't block status update
      }
    } catch (e) {
      print('❌ Error updating feedback status: $e');
      rethrow;
    }
  }

  /// Update feedback with response
  Future<void> updateFeedbackResponse(
      String feedbackId, String response) async {
    try {
      await _firestore.collection('feedbacks').doc(feedbackId).update({
        'response': response,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error updating feedback response: $e');
      rethrow;
    }
  }

  /// Get feedback by ID
  Future<entity.Feedback?> getFeedbackById(String feedbackId) async {
    try {
      final doc =
          await _firestore.collection('feedbacks').doc(feedbackId).get();
      if (!doc.exists) return null;
      return entity.Feedback.fromJson(doc.data()!);
    } catch (e) {
      print('❌ Error getting feedback by ID: $e');
      return null;
    }
  }

  /// Get feedbacks by status
  Future<List<entity.Feedback>> getFeedbacksByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedbacks')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return entity.Feedback.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error getting feedbacks by status: $e');
      return [];
    }
  }

  /// Delete feedback (admin only)
  Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedbacks').doc(feedbackId).delete();
    } catch (e) {
      print('❌ Error deleting feedback: $e');
      rethrow;
    }
  }
}
