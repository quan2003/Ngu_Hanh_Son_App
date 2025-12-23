import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Logger _logger = Logger();

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      _logger.d('📊 Screen view logged: $screenName');
    } catch (e) {
      _logger.e('Error logging screen view: $e');
    }
  }

  /// Log login event
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
      _logger.d('📊 Login logged');
    } catch (e) {
      _logger.e('Error logging login: $e');
    }
  }

  /// Log signup event
  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method ?? 'email');
      _logger.d('📊 Sign up logged');
    } catch (e) {
      _logger.e('Error logging sign up: $e');
    }
  }

  /// Log search event
  Future<void> logSearch({required String searchTerm}) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      _logger.d('📊 Search logged: $searchTerm');
    } catch (e) {
      _logger.e('Error logging search: $e');
    }
  }

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Convert Map<String, dynamic> to Map<String, Object>
      final Map<String, Object>? convertedParams = parameters?.map(
        (key, value) => MapEntry(key, value as Object),
      );

      await _analytics.logEvent(
        name: name,
        parameters: convertedParams,
      );
      _logger.d('📊 Event logged: $name');
    } catch (e) {
      _logger.e('Error logging event: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _logger.d('📊 User ID set: $userId');
    } catch (e) {
      _logger.e('Error setting user ID: $e');
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      _logger.d('📊 User property set: $name = $value');
    } catch (e) {
      _logger.e('Error setting user property: $e');
    }
  }

  /// Log feedback submitted
  Future<void> logFeedbackSubmitted({
    required String category,
    required String contentType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'feedback_submitted',
        parameters: <String, Object>{
          'category': category,
          'content_type': contentType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _logger.d('📊 Feedback submitted logged');
    } catch (e) {
      _logger.e('Error logging feedback: $e');
    }
  }

  /// Log chi bo view
  Future<void> logChiBoView(
      {required String chiBoId, required String chiBoName}) async {
    try {
      await _analytics.logEvent(
        name: 'chi_bo_view',
        parameters: <String, Object>{
          'chi_bo_id': chiBoId,
          'chi_bo_name': chiBoName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _logger.d('📊 Chi Bo view logged: $chiBoName');
    } catch (e) {
      _logger.e('Error logging chi bo view: $e');
    }
  }

  /// Log map interaction
  Future<void> logMapInteraction({required String action}) async {
    try {
      await _analytics.logEvent(
        name: 'map_interaction',
        parameters: <String, Object>{
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _logger.d('📊 Map interaction logged: $action');
    } catch (e) {
      _logger.e('Error logging map interaction: $e');
    }
  }

  /// Get analytics observer for NavigatorObserver
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }
}
