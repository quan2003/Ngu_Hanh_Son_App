import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/push_notification_service.dart';

/// Provider for push notification service
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// Provider to check if notifications are initialized
final notificationsInitializedProvider = StateProvider<bool>((ref) => false);
