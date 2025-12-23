import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/analytics_service.dart';
import '../../domain/entities/app_user.dart';

// Provider for FirebaseAuthService
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Provider for UserService
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider for FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

// Provider for Analytics Service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Provider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider for current AppUser with role from Firestore
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) return null;

  final firestoreService = ref.watch(firestoreServiceProvider);
  final userService = ref.watch(userServiceProvider);

  // Try to get from Firestore first
  AppUser? appUser = await firestoreService.getUser(user.uid);

  if (appUser == null) {
    // If not in Firestore, create new user and determine role
    final role = await firestoreService.getUserRole(user.email ?? '');

    appUser = AppUser.fromFirebaseUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      role: role,
    );

    // Save to both Firestore and local
    await firestoreService.saveUser(appUser);
    await userService.saveUser(appUser);
  } else {
    // User exists in Firestore, check if role needs to be updated
    // This ensures admin status is always up-to-date
    final shouldBeAdmin = await firestoreService.isAdminEmail(user.email ?? '');
    final currentRole = shouldBeAdmin ? UserRole.admin : UserRole.user;

    // Only update if role has actually changed
    if (appUser.role != currentRole) {
      appUser = appUser.copyWith(role: currentRole);
      await firestoreService.updateUserRole(user.uid, currentRole);
      await userService.saveUser(appUser);
    }
  }

  return appUser;
});

// Provider to check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final appUser = await ref.watch(currentAppUserProvider.future);
  return appUser?.isAdmin ?? false;
});
