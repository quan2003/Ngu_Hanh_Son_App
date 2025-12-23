/// Validation utilities
class ValidationUtils {
  ValidationUtils._();

  /// Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number (Vietnam)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s+'), ''));
  }

  /// Validate password (min 6 characters)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Get email error message
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!isValidEmail(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  /// Get phone error message
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (!isValidPhoneNumber(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  /// Get password error message
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (!isValidPassword(value)) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }
}
