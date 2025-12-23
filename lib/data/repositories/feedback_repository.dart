import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../domain/entities/feedback.dart' as entity;
import '../services/supabase_storage_service.dart';
import '../services/push_notification_service.dart';

class FeedbackRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PushNotificationService _notificationService =
      PushNotificationService();

  // Lazy initialization - only create when Supabase is ready
  SupabaseStorageService? _storageService;

  SupabaseStorageService get _storage {
    _storageService ??= SupabaseStorageService();
    return _storageService!;
  }

  /// Submit new feedback
  Future<String> submitFeedback({
    required String title,
    required String description,
    required String category,
    required List<File> images,
    Map<String, double>? location,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }
      print('📤 Submitting feedback for user: ${user.uid}');

      // Upload images to Supabase Storage
      List<String> imageUrls = [];

      if (images.isNotEmpty) {
        // Check if Supabase is initialized
        if (!SupabaseStorageService.isInitialized) {
          print('⚠️ Supabase chưa được khởi tạo, bỏ qua upload ảnh');
        } else {
          print('📸 Uploading ${images.length} images to Supabase Storage...');
          try {
            imageUrls = await _storage.uploadImages(
              imageFiles: images,
              userId: user.uid,
            );
            print('✅ Successfully uploaded ${imageUrls.length} images');
          } catch (e) {
            print('⚠️ Error uploading images: $e');
            // Continue without images if upload fails
          }
        }
      }

      // Create feedback document
      final docRef = _firestore.collection('feedbacks').doc();
      final feedback = entity.Feedback(
        id: docRef.id,
        userId: user.uid,
        title: title,
        description: description,
        category: category,
        status: 'Đã nhận',
        images: imageUrls,
        location: location,
        createdAt: DateTime.now(),
      );
      print('💾 Saving feedback to Firestore: ${docRef.id}');
      await docRef.set(feedback.toJson());
      print('✅ Feedback submitted successfully: ${docRef.id}');

      // Send notification to all admins about new feedback
      try {
        await _notificationService.sendNotificationToAllAdmins(
          title: '📬 Phản ánh mới: $title',
          body: 'Danh mục: $category - $description',
          data: {
            'type': 'new_feedback',
            'feedbackId': docRef.id,
            'category': category,
          },
        );
        print('✅ Sent notification to admins');
      } catch (e) {
        print('⚠️ Failed to send notification to admins: $e');
        // Don't throw - notification failure shouldn't block feedback submission
      }

      return docRef.id;
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Get user's feedbacks
  Future<List<entity.Feedback>> getUserFeedbacks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in');
        throw Exception('Người dùng chưa đăng nhập');
      }

      print('📥 Fetching feedbacks for user: ${user.uid}');

      final querySnapshot = await _firestore
          .collection('feedbacks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ Found ${querySnapshot.docs.length} feedbacks');

      return querySnapshot.docs.map((doc) {
        print('📄 Feedback doc: ${doc.id}');
        return entity.Feedback.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error getting user feedbacks: $e');
      return [];
    }
  }

  /// Stream user's feedbacks (real-time updates)
  Stream<List<entity.Feedback>> streamUserFeedbacks() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in for stream');
        return Stream.value([]);
      }

      print('🔄 Starting feedback stream for user: ${user.uid}');

      return _firestore
          .collection('feedbacks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        print('🔄 Stream update: ${snapshot.docs.length} feedbacks');
        return snapshot.docs.map((doc) {
          print('📄 Stream feedback: ${doc.id}');
          return entity.Feedback.fromJson(doc.data());
        }).toList();
      });
    } catch (e) {
      print('❌ Error streaming user feedbacks: $e');
      return Stream.value([]);
    }
  }

  /// Delete feedback (only if status is not processed)
  Future<void> deleteFeedback(String feedbackId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final doc =
          await _firestore.collection('feedbacks').doc(feedbackId).get();
      if (!doc.exists) {
        throw Exception('Phản ánh không tồn tại');
      }

      final feedback = entity.Feedback.fromJson(doc.data()!);
      if (feedback.userId != user.uid) {
        throw Exception('Bạn không có quyền xóa phản ánh này');
      }

      if (feedback.status != 'Đã nhận') {
        throw Exception('Không thể xóa phản ánh đã được xử lý');
      } // Delete images from Supabase Storage
      for (final imageUrl in feedback.images) {
        try {
          await _storage.deleteImage(imageUrl);
        } catch (e) {
          print('⚠️ Error deleting image: $e');
        }
      }

      await _firestore.collection('feedbacks').doc(feedbackId).delete();
    } catch (e) {
      print('❌ Error deleting feedback: $e');
      rethrow;
    }
  }
}
