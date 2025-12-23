# Cập nhật Đăng nhập bằng Số điện thoại - FIXED v2

## Ngày cập nhật: 17/12/2025

## Vấn đề đã sửa

### 1. **Đăng nhập bằng SĐT không tạo user trong Firestore**

- **Vấn đề**: Khi đăng nhập bằng số điện thoại, thông tin user không được lưu vào Firestore như khi đăng nhập bằng email.
- **Giải pháp**: Thêm logic tạo/cập nhật user trong Firestore ngay sau khi đăng nhập bằng SĐT thành công trong hàm `_handlePhoneLoginSuccess()`.

### 2. **User đăng nhập bằng SĐT bị yêu cầu xác thực email** ✅ FIXED

- **Vấn đề**: User đăng nhập bằng số điện thoại vẫn bị redirect đến màn hình xác thực email khi đăng nhập lại.
- **Root Cause**:
  - Router và Login Screen đều check `!user.emailVerified` mà KHÔNG check xem user có phải phone login
  - Phone user không có email nên `emailVerified` luôn = false
- **Giải pháp**:
  - Thêm field `skipEmailVerification` vào entity `AppUser`
  - **⭐ Ưu tiên check `hasPhoneNumber` TRƯỚC** trong cả Router và Login Screen
  - Chỉ check `skipEmailVerification` flag nếu KHÔNG phải phone user
  - Cập nhật Router để bỏ qua email verification check cho phone users

### 3. **User phải đăng nhập lại sau khi đóng app** ✅ FIXED

- **Vấn đề**: Firebase Auth đã lưu session nhưng router redirect sai
- **Giải pháp**: Router giờ cho phép user tiếp tục vào app nếu họ đã đăng nhập, không force redirect về email verification

## Thay đổi chi tiết

### 1. Router (`lib/core/router.dart`) ⭐ MỚI

**Vấn đề**: Router tự động redirect về email verification cho mọi user có `!emailVerified`, kể cả phone users.

**Sửa**: Thêm check `isPhoneUser` và bỏ qua email verification cho phone users:

```dart
// ⭐ Check if this is a phone login user
final isPhoneUser = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

// Đã đăng nhập nhưng email chưa verify
// ⭐ QUAN TRỌNG: Bỏ qua check nếu là phone user hoặc admin
if (!user.emailVerified && !isAdmin && !isPhoneUser) {
  // Phone users KHÔNG cần verify email

  // Cho phép user tiếp tục, login screen sẽ handle verification check
  return null;
}
```

**Kết quả**:

- Phone users không bị redirect về email verification
- Email users vẫn được check trong login screen (dựa trên skipEmailVerification flag)
- User không bị logout sau khi đóng app

### 2. Entity `AppUser` (`lib/domain/entities/app_user.dart`)

**Thêm fields mới:**

```dart
final DateTime? updatedAt;
final bool? skipEmailVerification; // For phone login users who don't need email verification
```

**Cập nhật constructor, factory, toJson(), fromJson(), copyWith()** để support 2 fields mới.

### 3. Login Screen (`lib/presentation/screens/auth/login_screen.dart`)

#### A. Thêm import

```dart
import '../../../domain/entities/app_user.dart';
```

#### B. Cập nhật logic kiểm tra email verification trong `_handleLogin()` ⭐ QUAN TRỌNG

**Logic MỚI - Ưu tiên check phone user:**

```dart
final user = authService.currentUser;

if (user != null) {
  // ⭐ Check if this is a phone login user (has phone number)
  final hasPhoneNumber = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

  // Nếu là phone user → BỎ QUA email verification hoàn toàn
  if (hasPhoneNumber) {
    debugPrint('📱 Phone login detected - skipping email verification check');
  }
  // Nếu là email user VÀ email chưa verified → Check skipEmailVerification flag
  else if (!authService.isEmailVerified) {
    // Check flag from Firestore...
    if (!skipVerification) {
      // Redirect to email verification
      return;
    }
  }
}
```

**Điểm khác biệt**:

- ✅ **Check `hasPhoneNumber` TRƯỚC**, bỏ qua hoàn toàn email verification
- ✅ Chỉ check `skipEmailVerification` flag nếu KHÔNG phải phone user
- ✅ Đơn giản, rõ ràng, không bị nhầm lẫn

#### C. Cập nhật `_handlePhoneLoginSuccess()`

Thêm logic tạo/cập nhật user trong Firestore:

```dart
// 🔥 TẠO/CẬP NHẬT USER TRONG FIRESTORE CHO PHONE LOGIN
debugPrint('📱 Creating/updating user in Firestore for phone login...');
try {
  final firestoreService = ref.read(firestoreServiceProvider);

  // Check if user exists in Firestore
  var appUser = await firestoreService.getUser(user.uid);

  if (appUser == null) {
    // User doesn't exist, create new user with phone number
    debugPrint('🆕 Creating new user for phone: ${user.phoneNumber}');

    final role = UserRole.user; // Phone users are regular users by default

    appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '', // Phone login may not have email
      phoneNumber: user.phoneNumber,
      displayName: user.displayName ?? user.phoneNumber ?? 'User',
      photoURL: user.photoURL,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      skipEmailVerification: true, // ⭐ QUAN TRỌNG: Phone login không cần verify email
    );

    // Save to Firestore
    await firestoreService.saveUser(appUser);
    debugPrint('✅ User created in Firestore: ${user.uid}');
  } else {
    // User exists, ensure skipEmailVerification is true for phone users
    if (appUser.skipEmailVerification != true) {
      debugPrint('📝 Updating skipEmailVerification flag for phone user');
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
```

## Flow hoạt động mới

### Đăng nhập bằng Email

1. User nhập email + password
2. Firebase Auth xác thực
3. Kiểm tra email verification:
   - Nếu email chưa verify VÀ không có flag `skipEmailVerification` → Redirect đến email verification
   - Nếu email đã verify HOẶC có flag `skipEmailVerification` → Cho phép đăng nhập
4. Lưu FCM token, khởi động notification listener
5. Navigate to home

### Đăng nhập bằng SĐT (Mới)

1. User nhập số điện thoại → Gửi OTP
2. User nhập OTP → Firebase Auth xác thực
3. **✨ Tạo/cập nhật user trong Firestore với `skipEmailVerification: true`**
4. **✨ Không bị redirect đến email verification (vì có phoneNumber hoặc skipEmailVerification flag)**
5. Lưu FCM token, khởi động notification listener
6. Navigate to home

## Lợi ích

1. ✅ **Consistency**: User đăng nhập bằng SĐT giờ được lưu đầy đủ thông tin như email login
2. ✅ **UX tốt hơn**: Phone user không bị yêu cầu verify email (vô lý)
3. ✅ **Data integrity**: Mọi user đều có record trong Firestore
4. ✅ **Flexible**: Flag `skipEmailVerification` có thể dùng cho các trường hợp đặc biệt khác

## Testing

### Test Case 1: Đăng nhập bằng SĐT lần đầu

1. Đăng nhập bằng SĐT chưa tồn tại
2. ✅ User được tạo trong Firestore với `skipEmailVerification: true`
3. ✅ Đăng nhập thành công, không bị yêu cầu verify email

### Test Case 2: Đăng nhập bằng SĐT lần 2+

1. Đăng nhập bằng SĐT đã tồn tại
2. ✅ User được cập nhật flag `skipEmailVerification: true` (nếu chưa có)
3. ✅ Đăng nhập thành công, không bị yêu cầu verify email

### Test Case 3: Đăng nhập bằng Email (chưa verify)

1. Đăng ký email mới, chưa verify
2. ✅ Bị redirect đến email verification screen
3. ✅ Không thể vào home

### Test Case 4: Đăng nhập bằng Email (đã verify hoặc có flag skip)

1. Email đã verify HOẶC có `skipEmailVerification: true` trong Firestore
2. ✅ Đăng nhập thành công, không bị redirect
3. ✅ Navigate to home

## Notes

- Field `skipEmailVerification` là **optional** (nullable) để backward compatibility với user cũ
- Phone users được set role mặc định là `UserRole.user` (không phải admin)
- Nếu không tạo được user trong Firestore (permission error), app vẫn tiếp tục hoạt động (log warning only)
