/// App Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Trung tâm Dữ liệu Đảng Bộ';
  static const String appSubtitle = 'Phường Ngũ Hành Sơn';
  static const String appVersion = 'v1.0.0';

  // API
  static const String baseUrl = 'https://api.nguhanhson.vn/api/v1';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data'; // Routes
  static const String splashRoute = '/';
  static const String welcomeRoute = '/welcome';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String emailVerificationRoute = '/email-verification';
  static const String homeRoute = '/home';
  static const String dashboardRoute = '/dashboard';
  static const String chiBoRoute = '/chi-bo';
  static const String mapRoute = '/map';
  static const String feedbackRoute = '/feedback';

  // Contact
  static const String hotline = '0236.3847.999';
  static const String email = 'dangbo@nguhanhson.vn';
  static const String privacyPolicyUrl = 'https://nguhanhson.vn/privacy';

  // Map
  static const double defaultLatitude = 16.0544;
  static const double defaultLongitude = 108.2022;
  static const double defaultZoom = 15.0;
  // Pagination
  static const int defaultPageSize = 20;
  // Animation
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
}
