import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      _logger.i('User registered successfully: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    }
  }

  // Login with email and password
  Future<UserCredential?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload user to get latest profile data including displayName
      await userCredential.user?.reload();
      final updatedUser = _auth.currentUser;

      _logger.i('User logged in successfully: ${updatedUser?.email}');
      _logger.i('Display name: ${updatedUser?.displayName}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  // Phone authentication - Send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(UserCredential credential) onAutoVerified,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logger.i('Phone verification completed automatically');
          final userCredential = await _auth.signInWithCredential(credential);
          onAutoVerified(userCredential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _logger.e('Phone verification failed: ${e.code} - ${e.message}');
          onError(_handleAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _logger.i('OTP sent to: $phoneNumber');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logger.i('Code auto retrieval timeout');
        },
        forceResendingToken: forceResendingToken,
      );
    } catch (e) {
      _logger.e('Verify phone number error: $e');
      onError(e.toString());
    }
  }

  // Phone authentication - Verify OTP
  Future<UserCredential?> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _logger.i(
          'User logged in with phone successfully: ${userCredential.user?.phoneNumber}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Sign in with phone error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Logout error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Reset password error: $e');
      rethrow;
    }
  } // Send email verification

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        // Custom Action Code Settings for Vietnamese email template
        // Note: Firebase's default template message cannot be customized via code
        // Only Subject and Sender name can be changed in Firebase Console
        // For fully custom emails, you would need to implement a custom email service
        // using Cloud Functions with SendGrid, Mailgun, or similar services

        final actionCodeSettings = ActionCodeSettings(
          // URL to redirect after clicking the verification link
          // This must be whitelisted in Firebase Console:
          // Authentication > Settings > Authorized domains
          url: 'https://nhs-flutter.firebaseapp.com/',
          handleCodeInApp: false,
          // iOS settings (if you have iOS app)
          iOSBundleId: 'com.nguhanhson.dangbo',
          // Android settings (if you have Android app)
          androidPackageName: 'com.nguhanhson.dangbo',
          androidInstallApp: false,
        );

        await user.sendEmailVerification(actionCodeSettings);
        _logger.i('Verification email sent to: ${user.email}');
      } else if (user == null) {
        throw Exception('Không có người dùng đăng nhập');
      } else {
        throw Exception('Email đã được xác thực');
      }
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Send verification email error: $e');
      rethrow;
    }
  }

  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      _logger.i('User data reloaded');
    } catch (e) {
      _logger.e('Reload user error: $e');
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Không có người dùng đăng nhập');
      }
      await user.updateDisplayName(displayName);
      await user.reload();
      _logger.i('Display name updated to: $displayName');
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Update display name error: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Không có người dùng đăng nhập');
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      _logger.i('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Change password error: $e');
      rethrow;
    }
  } // Create user account (Admin function - requires secondary Firebase instance)

  // WARNING: This will log out the current admin user!
  // For production, use Firebase Admin SDK from backend
  Future<Map<String, dynamic>> createUserAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create new user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUserId = userCredential.user?.uid;

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      _logger.i('User account created: $email with ID: $newUserId');

      // Return user ID and credential BEFORE signing out
      // This allows caller to save data to Firestore first
      return {
        'userId': newUserId,
        'userCredential': userCredential,
      };
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Create user account error: $e');
      rethrow;
    }
  }

  // Sign out current user (used after creating new user)
  Future<void> signOutCurrentUser() async {
    try {
      await _auth.signOut();
      _logger.i('User signed out');
    } catch (e) {
      _logger.e('Sign out error: $e');
      rethrow;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng. Vui lòng sử dụng email khác.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác. Vui lòng thử lại.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ.';
      case 'billing-not-enabled':
        return 'Để gửi SMS thật, cần nâng cấp Firebase lên Blaze Plan.\n\nVui lòng sử dụng số điện thoại test hoặc nâng cấp Firebase project.';
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ. Vui lòng kiểm tra lại.';
      case 'invalid-verification-code':
        return 'Mã OTP không đúng. Vui lòng kiểm tra lại.';
      case 'session-expired':
        return 'Phiên làm việc đã hết hạn. Vui lòng gửi lại mã OTP.';
      default:
        return 'Đã xảy ra lỗi: ${e.message ?? "Lỗi không xác định"}';
    }
  }
}
