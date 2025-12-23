import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_feedback_repository.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../../data/services/system_settings_service.dart';
import '../../domain/entities/feedback.dart';
import '../../domain/entities/user.dart';

// Repositories
final adminFeedbackRepositoryProvider =
    Provider<AdminFeedbackRepository>((ref) {
  return AdminFeedbackRepository();
});

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepository();
});

// System Settings Service
final systemSettingsServiceProvider = Provider<SystemSettingsService>((ref) {
  return SystemSettingsService();
});

// Stream all feedbacks for admin
final adminFeedbacksStreamProvider = StreamProvider<List<Feedback>>((ref) {
  final repository = ref.watch(adminFeedbackRepositoryProvider);
  return repository.streamAllFeedbacks();
});

// Stream all users for admin
final adminUsersStreamProvider = StreamProvider<List<User>>((ref) {
  final repository = ref.watch(adminUserRepositoryProvider);
  return repository.streamAllUsers();
});

// Get statistics with real-time updates
final adminStatisticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(adminUserRepositoryProvider);
  return repository.streamStatistics();
});

// User by ID provider
final userByIdProvider = FutureProvider.family<User?, String>((ref, userId) {
  final repository = ref.watch(adminUserRepositoryProvider);
  return repository.getUserById(userId);
});
