import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/supabase_notification_service.dart';
import '../../domain/models/notification_model.dart';
import 'auth_provider.dart';

// Provider for NotificationService (Firebase - legacy)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider for Supabase NotificationService (NEW - recommended)
final supabaseNotificationServiceProvider =
    Provider<SupabaseNotificationService>((ref) {
  return SupabaseNotificationService();
});

// Provider for user notifications stream (Supabase)
final userNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final notificationService = ref.watch(supabaseNotificationServiceProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return notificationService.getUserNotifications(user.uid);
});

// Provider for unread count stream (Supabase)
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  final notificationService = ref.watch(supabaseNotificationServiceProvider);

  if (user == null) {
    return Stream.value(0);
  }

  return notificationService.streamUnreadCount(user.uid);
});

// Provider for all notifications - admin only (Supabase)
final allNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final notificationService = ref.watch(supabaseNotificationServiceProvider);
  return notificationService.getAllNotifications();
});
