import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/push_notification_service.dart';
import '../../../data/services/notification_listener_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_animated_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Login method selection
  bool _isPhoneLogin = false; // false = Email, true = Phone
  // OTP verification state
  String? _verificationId;
  bool _otpSent = false;

  // Countdown timer for resend OTP
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handlePhoneLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(firebaseAuthServiceProvider);

      if (!_otpSent) {
        // Send OTP
        String phoneNumber = _phoneController.text.trim();
        // Add Vietnam country code if not present
        if (!phoneNumber.startsWith('+')) {
          phoneNumber =
              '+84${phoneNumber.substring(1)}'; // Remove leading 0 and add +84
        }

        await authService.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          onCodeSent: (verificationId) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            _startResendCountdown(); // Start countdown timer
            CustomAnimatedDialog.showSuccess(
              context: context,
              title: 'Mã OTP đã được gửi',
              message: 'Vui lòng kiểm tra tin nhắn điện thoại của bạn.',
            );
          },
          onError: (error) {
            setState(() => _isLoading = false);
            CustomAnimatedDialog.showError(
              context: context,
              title: 'Gửi OTP thất bại',
              message: error,
            );
          },
          onAutoVerified: (credential) async {
            // Auto verification successful
            await _handlePhoneLoginSuccess();
          },
        );
      } else {
        // Verify OTP
        if (_verificationId == null) {
          throw Exception('Verification ID not found');
        }

        await authService.signInWithPhoneNumber(
          verificationId: _verificationId!,
          smsCode: _otpController.text.trim(),
        );

        await _handlePhoneLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Đăng nhập thất bại',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handlePhoneLoginSuccess() async {
    if (!mounted) return;

    setState(() => _isLoading = false);

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final user = authService.currentUser;

      if (user != null) {
        // 🔥 TẠO/CẬP NHẬT USER TRONG FIRESTORE CHO PHONE LOGIN
        debugPrint('📱 Creating/updating user in Firestore for phone login...');
        try {
          final firestoreService = ref.read(firestoreServiceProvider);

          // Check if user exists in Firestore
          var appUser = await firestoreService.getUser(user.uid);

          if (appUser == null) {
            // User doesn't exist, create new user with phone number
            debugPrint('🆕 Creating new user for phone: ${user.phoneNumber}');

            final role =
                UserRole.user; // Phone users are regular users by default

            appUser = AppUser(
              uid: user.uid,
              email: user.email ?? '', // Phone login may not have email
              phoneNumber: user.phoneNumber,
              displayName: user.displayName ?? user.phoneNumber ?? 'User',
              photoURL: user.photoURL,
              role: role,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              skipEmailVerification:
                  true, // ⭐ QUAN TRỌNG: Phone login không cần verify email
            );

            // Save to Firestore
            await firestoreService.saveUser(appUser);
            debugPrint('✅ User created in Firestore: ${user.uid}');
          } else {
            // User exists, ensure skipEmailVerification is true for phone users
            if (appUser.skipEmailVerification != true) {
              debugPrint(
                  '📝 Updating skipEmailVerification flag for phone user');
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'skipEmailVerification': true});
            }
          }

          // Invalidate the provider to refresh user data
          ref.invalidate(currentAppUserProvider);
        } catch (e) {
          debugPrint('❌ Failed to create/update user in Firestore: $e');
        }

        // Save FCM token for push notifications
        debugPrint('🔐 Login successful, setting up notifications...');
        try {
          final pushNotificationService = PushNotificationService();
          debugPrint('👤 Current user: ${user.uid}');

          if (pushNotificationService.isInitialized) {
            debugPrint('💾 Saving FCM token...');
            await pushNotificationService.saveFCMToken(user.uid);
            debugPrint('✅ FCM token saved for user: ${user.uid}');

            debugPrint('🎧 Starting notification listener...');
            final notificationListener = NotificationListenerService();
            await notificationListener.startListening(user.uid);
            debugPrint('✅ Notification listener started for user: ${user.uid}');
          }
        } catch (e) {
          debugPrint('❌ Failed to setup notifications: $e');
        }

        // Get updated user info
        final appUser = await ref.read(currentAppUserProvider.future);
        final isAdmin = appUser?.isAdmin ?? false;

        final displayText = appUser?.displayName?.isNotEmpty == true
            ? appUser!.displayName!
            : user.phoneNumber ?? 'người dùng';

        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Đăng nhập thành công!',
          message: isAdmin
              ? 'Chào mừng Quản trị viên!\n$displayText'
              : 'Chào mừng bạn quay trở lại!\n$displayText',
        );

        if (mounted) {
          context.go(AppConstants.homeRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Đăng nhập thất bại',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPhoneLogin) {
      await _handlePhoneLogin(); // Use Firebase Phone Auth
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.loginWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);

        final user = authService.currentUser;

        // ⭐ LOGIC MỚI: Chỉ check email verification cho EMAIL LOGIN, bỏ qua phone login
        if (user != null) {
          // Check if this is a phone login user (has phone number)
          final hasPhoneNumber =
              user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

          // Nếu là phone user → BỎ QUA email verification hoàn toàn
          if (hasPhoneNumber) {
            debugPrint(
                '📱 Phone login detected - skipping email verification check');
          }
          // Nếu là email user VÀ email chưa verified → Check skipEmailVerification flag
          else if (!authService.isEmailVerified) {
            debugPrint(
                '🔍 Email not verified, checking skipEmailVerification for user: ${user.uid}');

            try {
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();

              if (doc.exists) {
                final data = doc.data();
                final skipVerification =
                    data?['skipEmailVerification'] as bool? ?? false;

                debugPrint('✅ User data from Firestore: $data');
                debugPrint('✅ skipEmailVerification flag: $skipVerification');

                // Nếu KHÔNG có flag skip → Yêu cầu xác thực email
                if (!skipVerification) {
                  debugPrint(
                      '❌ Email verification required - redirecting to verification screen');
                  await CustomAnimatedDialog.showWarning(
                    context: context,
                    title: 'Email chưa xác thực',
                    message:
                        'Vui lòng xác thực email của bạn để tiếp tục.\nChúng tôi sẽ gửi lại email xác thực.',
                  );

                  if (mounted) {
                    context.go(AppConstants.emailVerificationRoute);
                  }
                  return; // ← DỪNG LẠI, không cho đăng nhập
                }

                // CÓ flag skip → Cho phép đăng nhập
                debugPrint(
                    '✅ Login allowed - skipVerification: $skipVerification');
              } else {
                // No document in Firestore, require verification for email login
                debugPrint(
                    '⚠️ User document not found in Firestore - requiring verification');
                await CustomAnimatedDialog.showWarning(
                  context: context,
                  title: 'Email chưa xác thực',
                  message:
                      'Vui lòng xác thực email của bạn để tiếp tục.\nChúng tôi sẽ gửi lại email xác thực.',
                );

                if (mounted) {
                  context.go(AppConstants.emailVerificationRoute);
                }
                return;
              }
            } catch (e) {
              // On error, require verification for safety
              debugPrint(
                  '❌ Error checking skipEmailVerification: $e - requiring verification');
              await CustomAnimatedDialog.showWarning(
                context: context,
                title: 'Email chưa xác thực',
                message:
                    'Vui lòng xác thực email của bạn để tiếp tục.\nChúng tôi sẽ gửi lại email xác thực.',
              );

              if (mounted) {
                context.go(AppConstants.emailVerificationRoute);
              }
              return;
            }
          } else {
            // Email is already verified
            debugPrint('✅ Email already verified');
          }
        }

        // Save FCM token for push notifications
        debugPrint('🔐 Login successful, setting up notifications...');
        try {
          final pushNotificationService = PushNotificationService();
          final user = authService.currentUser;

          debugPrint('👤 Current user: ${user?.uid}');
          debugPrint(
              '🔔 Push service initialized: ${pushNotificationService.isInitialized}');

          if (user == null) {
            debugPrint('⚠️ No user found after login');
          } else if (!pushNotificationService.isInitialized) {
            debugPrint(
                '⚠️ Push notification service not initialized yet, waiting...');
            // Wait a bit for service to initialize
            await Future.delayed(const Duration(milliseconds: 500));
            debugPrint(
                '🔔 After wait - Push service initialized: ${pushNotificationService.isInitialized}');
          }

          if (pushNotificationService.isInitialized && user != null) {
            debugPrint('💾 Saving FCM token...');
            // Save FCM token
            await pushNotificationService.saveFCMToken(user.uid);
            debugPrint('✅ FCM token saved for user: ${user.uid}');
            debugPrint('📱 Token: ${pushNotificationService.fcmToken}');

            debugPrint('🎧 Starting notification listener...');
            // Start listening for notifications
            final notificationListener = NotificationListenerService();
            await notificationListener.startListening(user.uid);
            debugPrint('✅ Notification listener started for user: ${user.uid}');
          } else {
            debugPrint(
                '⚠️ Could not save FCM token - service not ready or no user');
            debugPrint(
                '   Service initialized: ${pushNotificationService.isInitialized}');
            debugPrint('   User exists: ${user != null}');
          }
        } catch (e) {
          debugPrint('❌ Failed to setup notifications: $e');
          debugPrint('Stack trace: ${StackTrace.current}');
          // Don't block login if FCM fails
        }

        // Email verified, proceed to home
        // Get user role
        final appUser = await ref.read(currentAppUserProvider.future);
        final isAdmin = appUser?.isAdmin ?? false;

        // Get display text - use displayName if available, otherwise use email
        final displayText = appUser?.displayName?.isNotEmpty == true
            ? appUser!.displayName!
            : appUser?.email ?? 'người dùng';

        // Show success dialog with animation
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Đăng nhập thành công!',
          message: isAdmin
              ? 'Chào mừng Quản trị viên!\n$displayText'
              : 'Chào mừng bạn quay trở lại!\n$displayText',
        );

        // Navigate to home
        if (mounted) {
          context.go(AppConstants.homeRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Show error dialog with animation
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Đăng nhập thất bại',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo Bác Hồ
                Image.asset(
                  'assets/images/bac-ho.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 12),

                // Title
                const Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(
                    color: Color(0xFFCEC62A),
                    fontSize: 24,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6), // Subtitle
                const Text(
                  'Đăng nhập để sử dụng chức năng',
                  style: TextStyle(
                    color: Color(0xFFCEC62A),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 24),

                // Login Method Selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPhoneLogin = false;
                              _otpSent = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isPhoneLogin
                                  ? const Color(0xFFCEC62A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: !_isPhoneLogin
                                      ? Colors.black
                                      : Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: !_isPhoneLogin
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPhoneLogin = true;
                              _otpSent = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isPhoneLogin
                                  ? const Color(0xFFCEC62A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  color: _isPhoneLogin
                                      ? Colors.black
                                      : Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Số điện thoại',
                                  style: TextStyle(
                                    color: _isPhoneLogin
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show Email or Phone fields based on selection
                      if (!_isPhoneLogin) ...[
                        // Email Label
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'nguyenvana@gmail.com',
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Colors.black54, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!value.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        // Phone Number Label
                        const Text(
                          'Số điện thoại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Phone Number Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: '0987654321',
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                            prefixIcon: const Icon(Icons.phone_android,
                                color: Colors.black54, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                              return 'Số điện thoại không hợp lệ';
                            }
                            return null;
                          },
                          enabled: !_otpSent,
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: 12),

                          // OTP Label
                          const Text(
                            'Mã OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // OTP Field
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Nhập mã OTP 6 số',
                              hintStyle: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                              prefixIcon: const Icon(Icons.security,
                                  color: Colors.black54, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mã OTP';
                              }
                              if (value.length != 6) {
                                return 'Mã OTP phải có 6 số';
                              }
                              return null;
                            },
                          ),
                        ],
                      ], // Password field only for Email login
                      if (!_isPhoneLogin) ...[
                        const SizedBox(height: 12),

                        // Password Label
                        const Text(
                          'Mật khẩu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Nhập mật khẩu',
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Colors.black54, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black54,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.push(AppConstants.forgotPasswordRoute);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Quên mật khẩu',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCEC62A),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                  ),
                                )
                              : Text(
                                  _isPhoneLogin
                                      ? (_otpSent
                                          ? 'Xác nhận OTP'
                                          : 'Gửi mã OTP')
                                      : 'Đăng nhập',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ), // Resend OTP button for phone login
                      if (_isPhoneLogin && _otpSent) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _resendCountdown > 0
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Gửi lại sau $_resendCountdown giây',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _otpSent = false;
                                            _otpController.clear();
                                            _verificationId = null;
                                          });
                                        },
                                  style: TextButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        color: Color(0xFFFFD700),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Gửi lại mã OTP',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Register Link
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              context.go(AppConstants.registerRoute),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Bạn chưa có hồ sơ? ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Poppins',
                              ),
                              children: [
                                TextSpan(
                                  text: 'Đăng ký ngay.',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Footer Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFooterButton(
                              Icons.menu_book, 'Hướng dẫn\nsử dụng'),
                          _buildFooterButton(
                              Icons.help_outline, 'Câu hỏi\nthắc mắc'),
                          _buildFooterButton(Icons.phone, 'Liên hệ\nhỗ trợ'),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
