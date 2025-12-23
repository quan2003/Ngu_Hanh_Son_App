# 🔥 BUG FIX: Đăng nhập bằng SĐT bị redirect về Email Verification

## ❌ Vấn đề

1. User đăng nhập bằng SĐT vẫn bị yêu cầu xác thực email
2. User phải đăng nhập lại mỗi lần mở app

## ✅ Nguyên nhân

- **Router** và **Login Screen** đều check `!user.emailVerified` mà KHÔNG check xem user có phone number
- Phone user KHÔNG có email verified → bị stuck ở email verification screen
- Router tự động redirect về email verification → user không thể vào app

## 🛠️ Giải pháp

### 1. Router (`lib/core/router.dart`)

```dart
// ⭐ Check phone user TRƯỚC
final isPhoneUser = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

// Chỉ check email verification nếu KHÔNG phải phone user
if (!user.emailVerified && !isAdmin && !isPhoneUser) {
  // Allow user to continue
  return null;
}
```

### 2. Login Screen (`lib/presentation/screens/auth/login_screen.dart`)

```dart
// ⭐ Check phone user TRƯỚC
final hasPhoneNumber = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

if (hasPhoneNumber) {
  // Bỏ qua email verification hoàn toàn
  debugPrint('📱 Phone login - skipping email verification');
} else if (!authService.isEmailVerified) {
  // Chỉ check skipEmailVerification cho email users
  // ...
}
```

## 📊 Flow mới

### Đăng nhập bằng SĐT

```
SĐT → OTP → ✅ Tạo user (skipEmailVerification=true)
→ ✅ Vào Home (KHÔNG check email verification)
→ ✅ Đóng app → Mở lại → ✅ Vẫn đăng nhập
```

### Đăng nhập bằng Email

```
Email + Password → Check verification:
  - ✅ Email verified → Home
  - ✅ skipEmailVerification=true → Home
  - ❌ Email chưa verify + không có skip flag → Email Verification Screen
```

## 🎯 Kết quả

- ✅ Phone users KHÔNG bị yêu cầu verify email
- ✅ User KHÔNG bị logout sau khi đóng app
- ✅ Email users vẫn được yêu cầu verify nếu cần
- ✅ Logic đơn giản, dễ hiểu, ưu tiên check phone trước

## 📝 Files đã sửa

1. `lib/core/router.dart` - Bỏ qua email verification cho phone users
2. `lib/presentation/screens/auth/login_screen.dart` - Ưu tiên check phone user trước
3. `lib/domain/entities/app_user.dart` - Thêm fields `updatedAt`, `skipEmailVerification`

---

**Ngày sửa**: 17/12/2025
**Version**: 2.0 - FIXED
