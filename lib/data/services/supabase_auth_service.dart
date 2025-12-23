import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Send OTP to phone number
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function() onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      _logger.i('Sending OTP to: $phoneNumber');

      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );

      _logger.i('OTP sent successfully to: $phoneNumber');
      onSuccess();
    } on AuthException catch (e) {
      _logger.e('Supabase Auth Error: ${e.message}');
      onError(_handleAuthException(e));
    } catch (e) {
      _logger.e('Sign in with phone error: $e');
      onError(e.toString());
    }
  }

  // Verify OTP
  Future<AuthResponse?> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      _logger.i('Verifying OTP for: $phoneNumber');

      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );

      _logger.i('OTP verified successfully for: $phoneNumber');
      _logger.i('User ID: ${response.user?.id}');

      return response;
    } on AuthException catch (e) {
      _logger.e('Supabase Auth Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Verify OTP error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      rethrow;
    }
  }

  // Handle Supabase Auth exceptions
  String _handleAuthException(AuthException e) {
    switch (e.message) {
      case 'Invalid token':
        return 'Mã OTP không đúng. Vui lòng thử lại.';
      case 'Token expired':
        return 'Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.';
      case 'Invalid phone number':
        return 'Số điện thoại không hợp lệ. Vui lòng kiểm tra lại.';
      case 'SMS provider not configured':
        return 'Dịch vụ SMS chưa được cấu hình. Vui lòng liên hệ quản trị viên.';
      case 'Rate limit exceeded':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau vài phút.';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }

  // Login with email and password (for backward compatibility)
  Future<AuthResponse?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _logger.i('User logged in successfully: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      _logger.e('Supabase Auth Error: ${e.message}');
      throw _handleEmailAuthException(e);
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<AuthResponse?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      _logger.i('User registered successfully: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      _logger.e('Supabase Auth Error: ${e.message}');
      throw _handleEmailAuthException(e);
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    }
  }

  // Handle email auth exceptions
  String _handleEmailAuthException(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Email hoặc mật khẩu không đúng.';
      case 'Email not confirmed':
        return 'Vui lòng xác thực email trước khi đăng nhập.';
      case 'User already registered':
        return 'Email này đã được đăng ký.';
      case 'Password should be at least 6 characters':
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _logger.i('Password reset email sent to: $email');
    } on AuthException catch (e) {
      _logger.e('Supabase Auth Error: ${e.message}');
      throw _handleEmailAuthException(e);
    } catch (e) {
      _logger.e('Reset password error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<UserResponse?> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (photoUrl != null) updates['avatar_url'] = photoUrl;

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );

      _logger.i('User profile updated successfully');
      return response;
    } on AuthException catch (e) {
      _logger.e('Supabase Auth Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Update profile error: $e');
      rethrow;
    }
  }
}
