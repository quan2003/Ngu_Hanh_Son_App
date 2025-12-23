# 🏛️ Trung tâm Dữ liệu Đảng Bộ - Phường Ngũ Hành Sơn

**Phiên bản:** v1.0.0  
**Platform:** Flutter 3.24+ (Windows/Android/iOS)

## 📝 Giới thiệu

Ứng dụng quản lý dữ liệu Đảng Bộ, Chi Bộ, dân cư và tiếp nhận phản ánh góp ý từ người dân. Tích hợp bản đồ số với khả năng tra cứu thông tin 2 chiều.

## ✨ Tính năng

### 1. Xác thực

- Đăng nhập / Đăng ký
- Phân quyền: Citizen / Chi Bộ / Admin

### 2. Dashboard

- Thống kê tổng quan: dân số, hộ nghèo, chi bộ
- Biểu đồ trực quan
- Thao tác nhanh

### 3. Quản lý Chi Bộ

- Danh sách Chi Bộ theo khu vực
- Tìm kiếm, lọc
- Chi tiết: số dân, hộ nghèo, GCCS
- Xem trên bản đồ

### 4. Bản đồ

- Hiển thị vùng Chi Bộ (Polygon)
- Đánh dấu địa điểm: NVH, trường học, công viên
- Tìm kiếm 2 chiều
- Bộ lọc layer

### 5. Góp ý - Phản ánh

- Gửi phản ánh (tiêu đề, mô tả, ảnh, vị trí)
- Theo dõi trạng thái xử lý
- Lịch sử phản ánh

## 🚀 Cài đặt & Chạy

### Yêu cầu

- Flutter SDK 3.24+
- Dart 3.5+
- Windows 10+ / Android / iOS

### Các bước

```bash
# 1. Cài dependencies
flutter pub get

# 2. Chạy ứng dụng
flutter run -d windows    # Windows (khuyến nghị)
flutter run              # Android/iOS

# 3. Build APK
flutter build apk --release
```

## 📱 Màn hình

| STT | Màn hình      | Mô tả                     |
| --- | ------------- | ------------------------- |
| 1   | **Splash**    | Màn hình khởi động        |
| 2   | **Welcome**   | Giới thiệu + Đăng nhập/ký |
| 3   | **Login**     | Đăng nhập hệ thống        |
| 4   | **Register**  | Đăng ký tài khoản         |
| 5   | **Dashboard** | Thống kê Đảng Bộ          |
| 6   | **Chi Bộ**    | Quản lý Chi Bộ            |
| 7   | **Map**       | Bản đồ tương tác          |
| 8   | **Feedback**  | Góp ý - Phản ánh          |

## 🛠️ Công nghệ

- **Framework:** Flutter 3.24+
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Map:** flutter_map + OpenStreetMap
- **HTTP:** Dio + Retrofit
- **Storage:** SharedPreferences + SQLite

## 🎨 Màu sắc

- **Primary (Đỏ Đảng):** `#DA251C`
- **Secondary (Vàng Sao):** `#FFD700`

## 📂 Cấu trúc

```
lib/
├── main.dart                    # Entry point
├── core/
│   ├── constants/              # Hằng số
│   ├── theme/                  # Theme & màu sắc
│   ├── router.dart             # Định tuyến
│   └── utils/                  # Tiện ích
├── presentation/
│   ├── screens/                # Các màn hình
│   │   ├── splash/
│   │   ├── welcome/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── chi_bo/
│   │   ├── map/
│   │   └── feedback/
│   ├── widgets/                # Widget tái sử dụng
│   └── providers/              # State providers
├── data/
│   ├── models/                 # Data models
│   ├── datasources/            # API & Local data
│   └── repositories/           # Repository impl
└── domain/
    ├── entities/               # Business entities
    ├── repositories/           # Repository interfaces
    └── usecases/               # Business logic
```

## ⚠️ Lưu ý

### Chạy trên Web

Hiện tại Firebase chưa được cấu hình cho Web. Khuyến nghị dùng Windows hoặc Android.

```bash
# Nếu gặp lỗi "Undefined name 'main'" trên Chrome
# Chạy trên Windows thay thế:
flutter run -d windows
```

### Khắc phục lỗi build

```bash
# Clean và rebuild
flutter clean
flutter pub get
flutter run -d windows
```

## 📞 Liên hệ

- **Hotline:** 0236.3847.999
- **Email:** dangbo@nguhanhson.vn

## 📄 License

Copyright © 2025 Phường Ngũ Hành Sơn. All rights reserved.

---

**Phát triển bởi:** Phường Ngũ Hành Sơn  
**Cập nhật:** 23/10/2025
