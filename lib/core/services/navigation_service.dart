import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Global navigation service for handling navigation from background/notifications
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get current BuildContext
  BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to notifications screen
  void navigateToNotifications() {
    if (context == null) {
      debugPrint('⚠️ No navigation context available');
      return;
    }

    try {
      context!.push('/notifications');
      debugPrint('✅ Navigated to notifications screen');
    } catch (e) {
      debugPrint('❌ Error navigating: $e');
    }
  }

  /// Navigate to feedback detail
  void navigateToFeedbackDetail(String feedbackId) {
    if (context == null) {
      debugPrint('⚠️ No navigation context available');
      return;
    }

    try {
      // Navigate to feedback screen first, then open detail
      context!.go('/');
      Future.delayed(const Duration(milliseconds: 500), () {
        // TODO: Open feedback detail dialog/screen
        debugPrint('📱 Should open feedback: $feedbackId');
      });
      debugPrint('✅ Navigated to feedback detail');
    } catch (e) {
      debugPrint('❌ Error navigating: $e');
    }
  }

  /// Handle notification action based on type
  void handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    debugPrint('🔔 Handling notification action: $type');

    switch (type) {
      case 'new_feedback':
        final feedbackId = data['feedbackId'] as String?;
        if (feedbackId != null) {
          navigateToFeedbackDetail(feedbackId);
        } else {
          navigateToNotifications();
        }
        break;

      case 'feedback_status_update':
        final feedbackId = data['feedbackId'] as String?;
        if (feedbackId != null) {
          navigateToFeedbackDetail(feedbackId);
        } else {
          navigateToNotifications();
        }
        break;

      default:
        // Default action: navigate to notifications screen
        navigateToNotifications();
    }
  }
}
