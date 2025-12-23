# Cập Nhật Tìm Kiếm Nâng Cao - Tổ Dân Phố

## Ngày: 20/12/2025

## Những thay đổi đã thực hiện:

### 1. **Cải thiện tìm kiếm trong `organization_provider.dart`**

Đã cập nhật `filteredToDanPhoProvider` để hỗ trợ tìm kiếm theo nhiều tiêu chí:

- ✅ **Tên tổ dân phố** (đã có từ trước)
- ✅ **Tổ trưởng** (leader) - đã có
- ✅ **Cán bộ phụ trách** (staffInCharge) - đã có
- ✅ **Số điện thoại tổ trưởng** (leaderPhone) - MỚI
- ✅ **Số điện thoại cán bộ** (staffPhone) - MỚI

### 2. **Provider tìm kiếm nâng cao mới**

Đã tạo `advancedFilteredToDanPhoProvider` hỗ trợ tìm kiếm theo:

- ✅ Tất cả các tiêu chí cơ bản ở trên
- ✅ **Mẹ Việt Nam Anh hùng** - tìm theo tên mẹ VNAH
- ✅ **Tổng nhân khẩu** - tìm theo số lượng dân số

### 3. **Cập nhật giao diện**

- Thay đổi hint text trong search bar: `"Tìm theo tổ, tổ trưởng, SĐT, cán bộ..."`

## Cách sử dụng:

### Tìm kiếm cơ bản (đã hoạt động):

Người dùng có thể gõ vào ô tìm kiếm:

- Tên tổ: `"Tổ 1"`, `"tổ dân phố 5"`
- Tên tổ trưởng: `"Nguyễn Văn A"`
- Tên cán bộ: `"Trần Thị B"`
- Số điện thoại: `"0901234567"`, `"0123"`

### Tìm kiếm nâng cao (nếu muốn sử dụng):

Để kích hoạt tìm kiếm nâng cao (bao gồm mẹ VNAH và tổng nhân khẩu), thay đổi trong file:
`lib/presentation/screens/to_dan_pho/to_dan_pho_screen.dart`

Thay:

```dart
final filteredOrgs = ref.watch(filteredToDanPhoProvider).value ?? [];
```

Bằng:

```dart
final filteredOrgs = ref.watch(advancedFilteredToDanPhoProvider).value ?? [];
```

## Các file đã chỉnh sửa:

1. `lib/presentation/providers/organization_provider.dart`

   - Cập nhật `filteredToDanPhoProvider` (tìm kiếm thêm SĐT)
   - Thêm `advancedFilteredToDanPhoProvider` (tìm kiếm mẹ VNAH, nhân khẩu)

2. `lib/presentation/screens/to_dan_pho/to_dan_pho_screen.dart`
   - Cập nhật hint text trong search bar

## Testing:

Chạy lệnh để test:

```bash
flutter analyze
flutter run
```

## Lưu ý:

- Provider cơ bản (`filteredToDanPhoProvider`) đã hoạt động tốt với SĐT
- Provider nâng cao (`advancedFilteredToDanPhoProvider`) cần thêm một bước để kích hoạt
- Tất cả các thay đổi tương thích ngược (backward compatible)
