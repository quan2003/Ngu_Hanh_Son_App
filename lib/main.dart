import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'core/config/environment.dart';
import 'core/config/supabase_config.dart';
import 'data/services/firestore_service.dart';
import 'data/services/push_notification_service.dart';
import 'data/services/supabase_storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'presentation/providers/theme_provider.dart';

/// Background message handler (must be top-level function)
/// This handles notifications when app is in background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('📬 Background message received (terminated state):');
  debugPrint('  Title: ${message.notification?.title}');
  debugPrint('  Body: ${message.notification?.body}');
  debugPrint('  Data: ${message.data}');

  // The notification will be automatically displayed by FCM
  // because we have configured it in AndroidManifest.xml
  debugPrint('✅ Background notification will be displayed by system');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment
  EnvironmentConfig.initialize();
  EnvironmentConfig.printInfo();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // Initialize Supabase for image storage
    try {
      await SupabaseStorageService.initialize(
        supabaseUrl: SupabaseConfig.supabaseUrl,
        supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
      );
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Supabase initialization failed: $e');
      debugPrint(
          '💡 Image upload will be disabled. Update credentials in lib/core/config/supabase_config.dart');
    }

    // Initialize Firestore admin config
    final firestoreService = FirestoreService();
    await firestoreService.initializeAdminConfig();
    debugPrint(
        '✅ Firestore admin config initialized'); // Initialize Push Notification Service
    final pushNotificationService = PushNotificationService();
    await pushNotificationService.initialize();
    debugPrint('✅ Push Notification Service initialized successfully');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return MaterialApp.router(
      title: 'Trung tâm Dữ liệu Đảng Bộ',
      theme: theme,
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      // Add locale configuration
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
