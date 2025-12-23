import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Service for handling file uploads to Supabase Storage
/// Free alternative to Firebase Storage with signed URLs
class SupabaseStorageService {
  static const String _bucketName = 'feedback-images';
  static const int _signedUrlExpirySeconds = 31536000; // 1 year

  // Lazy getter - only access client when needed
  SupabaseClient get _client {
    if (!Supabase.instance.isInitialized) {
      throw Exception(
          '❌ Supabase chưa được khởi tạo. Vui lòng kiểm tra main.dart');
    }
    return Supabase.instance.client;
  }

  /// Initialize Supabase (call this in main.dart)
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized successfully');
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => Supabase.instance.isInitialized;

  /// Upload a single image to Supabase Storage
  /// Returns the signed URL that can be stored in Firestore
  Future<String> uploadImage({
    required File imageFile,
    required String userId,
    String? customFileName,
  }) async {
    try {
      final fileExtension = path.extension(imageFile.path);
      final fileName = customFileName ??
          '${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'feedback_images/$userId/$fileName';

      debugPrint('📤 Uploading image to Supabase: $filePath');

      // Read file as bytes
      final fileBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      final uploadPath = await _client.storage.from(_bucketName).uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              upsert: false, // Don't overwrite existing files
            ),
          );

      debugPrint('✅ Image uploaded: $uploadPath');

      // Get signed URL (valid for 1 year)
      final signedUrl = await _client.storage
          .from(_bucketName)
          .createSignedUrl(filePath, _signedUrlExpirySeconds);

      debugPrint('🔗 Signed URL: $signedUrl');

      return signedUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image to Supabase: $e');
      rethrow;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadImages({
    required List<File> imageFiles,
    required String userId,
  }) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('📸 Uploading image ${i + 1}/${imageFiles.length}...');
        final url = await uploadImage(
          imageFile: imageFiles[i],
          userId: userId,
        );
        uploadedUrls.add(url);
      } catch (e) {
        debugPrint('❌ Failed to upload image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }

    return uploadedUrls;
  }

  /// Delete an image from Supabase Storage
  Future<void> deleteImage(String signedUrl) async {
    try {
      // Extract file path from signed URL
      final uri = Uri.parse(signedUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after the bucket name
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid Supabase Storage URL');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      debugPrint('🗑️ Deleting image: $filePath');

      await _client.storage.from(_bucketName).remove([filePath]);

      debugPrint('✅ Image deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting image from Supabase: $e');
      // Don't throw - we don't want to fail feedback deletion if image deletion fails
    }
  }

  /// Delete multiple images
  Future<void> deleteImages(List<String> signedUrls) async {
    for (final url in signedUrls) {
      await deleteImage(url);
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if bucket exists and is accessible
  Future<bool> checkBucketAccess() async {
    try {
      await _client.storage.from(_bucketName).list(
            path: '',
            searchOptions: const SearchOptions(limit: 1),
          );
      debugPrint('✅ Supabase Storage bucket accessible');
      return true;
    } catch (e) {
      debugPrint('❌ Supabase Storage bucket not accessible: $e');
      return false;
    }
  }
}
