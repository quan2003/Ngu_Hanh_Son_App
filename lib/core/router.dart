import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/welcome/welcome_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/email_verification_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/chi_bo/to_chuc_dang_list_screen.dart';
import '../presentation/screens/chi_bo/to_dan_pho_list_screen.dart';
import '../presentation/screens/admin/admin_panel_screen.dart';
import '../presentation/screens/admin/organization_data_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/help/help_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/map/map_screen_with_boundaries.dart';
import '../presentation/screens/map/test_boundaries_screen.dart';
import '../presentation/screens/household_stats/household_stats_screen.dart';
import 'constants/app_constants.dart';

// Helper class to convert Stream to ChangeNotifier for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Hardcoded admin emails - Must match FirestoreService
const List<String> _hardcodedAdminEmails = [
  'admin@gmail.com',
];

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.splashRoute,
  refreshListenable:
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isOnSplash = state.matchedLocation == AppConstants.splashRoute;
    final isOnAuth = state.matchedLocation == AppConstants.loginRoute ||
        state.matchedLocation == AppConstants.registerRoute ||
        state.matchedLocation == AppConstants.welcomeRoute ||
        state.matchedLocation == AppConstants.forgotPasswordRoute;
    final isOnEmailVerification =
        state.matchedLocation == AppConstants.emailVerificationRoute;

    // Đang ở splash, không redirect
    if (isOnSplash) {
      return null;
    }

    // Chưa đăng nhập
    if (user == null) {
      // Cho phép ở màn auth
      if (isOnAuth) return null;
      // Ngược lại, về welcome
      return AppConstants.welcomeRoute;
    } // Check if user is hardcoded admin
    final isAdmin =
        _hardcodedAdminEmails.contains(user.email?.toLowerCase().trim());

    // ⭐ Check if this is a phone login user
    final isPhoneUser =
        user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

    // Đã đăng nhập nhưng email chưa verify
    // ⭐ QUAN TRỌNG: Bỏ qua check nếu là phone user hoặc admin
    if (!user.emailVerified && !isAdmin && !isPhoneUser) {
      // Admin KHÔNG cần verify email
      // Phone users KHÔNG cần verify email

      // ✨ KHÔNG tự động redirect về email verification
      // Để login screen quyết định dựa trên skipEmailVerification flag
      // Cho phép user tiếp tục, login screen sẽ handle verification check

      // Cho phép ở email verification hoặc auth (để logout)
      if (isOnEmailVerification || isOnAuth) return null;

      // Allow user to continue to home/other screens
      // Login screen will check skipEmailVerification flag from Firestore
      return null;
    }

    // Đã đăng nhập và verify rồi (hoặc là admin)
    // Nếu đang ở auth screens, chuyển về home
    if (isOnAuth || isOnEmailVerification) {
      return AppConstants.homeRoute;
    }

    // Cho phép truy cập các màn khác
    return null;
  },
  routes: [
    GoRoute(
      path: AppConstants.splashRoute,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.welcomeRoute,
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppConstants.loginRoute,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.registerRoute,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppConstants.forgotPasswordRoute,
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppConstants.emailVerificationRoute,
      name: 'email-verification',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: AppConstants.homeRoute,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/organizations',
      name: 'organizations',
      builder: (context, state) => const ToChucDangListScreen(),
    ),
    GoRoute(
      path: '/to-dan-pho',
      name: 'to-dan-pho',
      builder: (context, state) => const ToDanPhoListScreen(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminPanelScreen(),
    ),
    GoRoute(
      path: '/admin/organizations',
      name: 'admin-organizations',
      builder: (context, state) => OrganizationDataScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/help',
      name: 'help',
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/map-boundaries',
      name: 'map-boundaries',
      builder: (context, state) => const MapScreenWithBoundaries(),
    ),
    GoRoute(
      path: '/test-boundaries',
      name: 'test-boundaries',
      builder: (context, state) => const TestBoundariesScreen(),
    ),
    GoRoute(
      path: '/household-stats',
      name: 'household-stats',
      builder: (context, state) => const HouseholdStatsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Không tìm thấy trang: ${state.uri}'),
    ),
  ),
);
