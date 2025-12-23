import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_animated_dialog.dart';
import '../../../data/services/push_notification_service.dart';
import '../../../data/services/supabase_notification_listener_service.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isCheckingVerification = false;
  Timer? _timer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Send verification email
  Future<void> _sendVerificationEmail() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.sendEmailVerification();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _resendCountdown = 60; // 60 seconds countdown
        });

        _startResendCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email xác thực đã được gửi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Start countdown for resend button
  void _startResendCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // Auto check verification status every 3 seconds
  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified(autoCheck: true);
    });
  }

  // Check if email is verified
  Future<void> _checkEmailVerified({bool autoCheck = false}) async {
    if (!autoCheck) {
      setState(() => _isCheckingVerification = true);
    }

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.reloadUser();
      if (authService.isEmailVerified) {
        _timer?.cancel();

        if (mounted) {
          if (!autoCheck) {
            setState(() => _isCheckingVerification = false);
          }

          // Setup FCM token after email verification
          debugPrint('✅ Email verified, setting up notifications...');
          try {
            final pushNotificationService = PushNotificationService();
            final user = authService.currentUser;

            if (user != null) {
              // Wait for push service to initialize if needed
              if (!pushNotificationService.isInitialized) {
                debugPrint('⏳ Waiting for push service to initialize...');
                await Future.delayed(const Duration(milliseconds: 500));
              }

              if (pushNotificationService.isInitialized) {
                // Save FCM token
                debugPrint('💾 Saving FCM token for user: ${user.uid}');
                await pushNotificationService.saveFCMToken(user.uid);
                debugPrint(
                    '✅ FCM token saved: ${pushNotificationService.fcmToken}');

                // Start notification listener
                debugPrint('🎧 Starting notification listener...');
                final notificationListener =
                    SupabaseNotificationListenerService();
                await notificationListener.startListening(user.uid);
                debugPrint('✅ Notification listener started');
              } else {
                debugPrint('⚠️ Push service not initialized yet');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error setting up notifications: $e');
            // Don't block the flow if FCM setup fails
          }

          await CustomAnimatedDialog.showSuccess(
            context: context,
            title: 'Xác thực thành công!',
            message:
                'Email của bạn đã được xác thực.\nChào mừng đến với ứng dụng!',
          );

          if (mounted) {
            context.go(AppConstants.homeRoute);
          }
        }
      } else if (!autoCheck && mounted) {
        setState(() => _isCheckingVerification = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Email chưa được xác thực. Vui lòng kiểm tra hộp thư.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!autoCheck && mounted) {
        setState(() => _isCheckingVerification = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Logout and go back to login
  Future<void> _handleLogout() async {
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.logout();

      if (mounted) {
        context.go(AppConstants.loginRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(firebaseAuthServiceProvider);
    final userEmail = authService.currentUser?.email ?? '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 33.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Email icon with animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCEC62A).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 60,
                          color: Color(0xFFCEC62A),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Title
                const Text(
                  'XÁC THỰC EMAIL',
                  style: TextStyle(
                    color: Color(0xFFCEC62A),
                    fontSize: 24,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                const Text(
                  'Chúng tôi đã gửi email xác thực đến',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 8),

                // User email
                Text(
                  userEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCEC62A),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 30),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCEC62A).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFCEC62A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vui lòng kiểm tra email và nhấn vào link xác thực',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            color: Color(0xFFCEC62A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kiểm tra cả thư mục Spam/Junk nếu không thấy email',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Check verification button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isCheckingVerification
                        ? null
                        : () => _checkEmailVerified(autoCheck: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCEC62A),
                      foregroundColor: const Color(0xFF121212),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isCheckingVerification
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF121212)),
                            ),
                          )
                        : const Text(
                            'Tôi đã xác thực',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: (_isLoading || _resendCountdown > 0)
                        ? null
                        : _sendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCEC62A),
                      side: const BorderSide(
                        color: Color(0xFFCEC62A),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFCEC62A)),
                            ),
                          )
                        : Text(
                            _resendCountdown > 0
                                ? 'Gửi lại sau $_resendCountdown giây'
                                : 'Gửi lại email',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // Auto check indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFCEC62A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Đang tự động kiểm tra...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Logout button
                TextButton(
                  onPressed: _handleLogout,
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
