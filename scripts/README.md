# 📚 NHS Firebase Scripts

Bộ sưu tập các script Node.js để quản lý dữ liệu Firebase cho ứng dụng NHS.

## 🚀 Cài Đặt

### Yêu Cầu

- Node.js 14+
- npm hoặc yarn
- File `firebase-admin-key.json` trong thư mục gốc (d:\NHS_APP\)

### Bước 1: Cài Dependencies

```powershell
cd d:\NHS_APP\scripts
npm install
```

Hoặc nếu chưa có npm project:

```powershell
npm init -y
npm install firebase-admin xlsx
```

---

## 📖 Các Script

### 1. 🔍 Preview Excel Data

Xem trước dữ liệu Excel trước khi upload

**Cách sử dụng:**

```powershell
npm run preview "D:\path\to\file.xlsx"
# hoặc
node preview_excel.js "D:\path\to\file.xlsx"
```

**Output:**

```
📊 Excel Preview
================================================================================

📁 File: Phuong_NHS_ToChuDang_ToDanPho.xlsx
📄 Total sheets: 2

Sheet names: ToChuDang_NHS, ToDanPho_NHS

================================================================================

📋 Sheet 1: "ToChuDang_NHS"
   Rows: 26
   Columns (9):
     1. ID
     2. LoaiToChu
     3. TenToChu
     ... (xem tất cả cột)

   📊 Preview (first 5 rows):
   ────────────────────────────────────────────────────────────────────────────
   Row 1:
     • ID: 1
     • LoaiToChu: Chi bộ
     • TenToChu: Chỉ bộ 1
     ...
```

**Khi nào dùng:**

- Trước khi upload lần đầu tiên
- Để kiểm tra cấu trúc file Excel
- Để xác nhận dữ liệu đầu vào

---

### 2. ⬆️ Upload Excel to Firebase

Đẩy dữ liệu Excel lên Firestore

**Cách sử dụng:**

```powershell
npm run upload "D:\path\to\file.xlsx"
# hoặc
node upload_excel_to_firebase.js "D:\path\to\file.xlsx"
```

**Điều kiện tiên quyết:**

1. ✅ File `firebase-admin-key.json` đã lưu tại `d:\NHS_APP\`
2. ✅ Firestore Security Rules cho phép write
3. ✅ File Excel có đúng format (xem phần Preview)

**Những gì script làm:**

1. Đọc tất cả sheet trong file Excel
2. Phân tích dữ liệu Chi bộ từ các hàng
3. Chuyển đổi sang format Firestore
4. Tải lên collection `chi_bo`
5. Tạo/cập nhật bản ghi `dang_bo` cho Phường Ngũ Hành Sơn
6. Khởi tạo admin config nếu chưa có

**Output mong đợi:**

```
🚀 Starting Excel to Firebase upload...
📁 File: D:\Downloads\file.xlsx

📊 Excel sheets found: [ 'ToChuDang_NHS', 'ToD anPho_NHS', ... ]

📄 Sheet: ToChuDang_NHS
   Rows: 26
   Columns: ID, LoaiToChu, TenToChu, ...

✅ Parsed 26 Chi bộ records

📤 Uploading 26 Chi bộ records to Firestore...
   ✅ Uploaded 26 records

📝 Creating/Updating Đảng bộ: Đảng bộ Phường Ngũ Hành Sơn
   ✅ Đảng bộ created/updated

🔐 Initializing admin config...
   ✅ Admin config initialized

✅ Upload completed successfully!
   - Uploaded 26 Chi bộ records
   - Created/Updated 1 Đảng bộ
   - Initialized admin config for future admin additions
```

---

### 3. 👨‍💼 Manage Admins

Quản lý danh sách admin (thêm, xóa, xem)

#### Xem danh sách admin

```powershell
npm run admin:list
# hoặc
node manage_admins.js list
```

**Output:**

```
👨‍💼 Current Admin List (3 admins):
   1. admin@nhs.vn
   2. admin@gmail.com
   3. quanly@nhs.vn
```

#### Thêm admin mới

```powershell
npm run admin:add "newemail@domain.com"
# hoặc
node manage_admins.js add "newemail@domain.com"
```

**Output:**

```
✅ Admin added successfully: newemail@domain.com

📋 Updated admin list:
   1. admin@nhs.vn
   2. admin@gmail.com
   3. quanly@nhs.vn
   4. newemail@domain.com
```

#### Xóa admin

```powershell
npm run admin:remove "admin@domain.com"
# hoặc
node manage_admins.js remove "admin@domain.com"
```

**Output:**

```
✅ Admin removed successfully: admin@domain.com

📋 Updated admin list:
   1. admin@nhs.vn
   2. quanly@nhs.vn
```

#### Reset admin list về mặc định

```powershell
npm run admin:reset
# hoặc
node manage_admins.js reset
```

---

### 4. 🗑️ Clear Collections

Xóa dữ liệu cũ từ Firestore (cần xác nhận)

**Xóa Chi bộ:**

```powershell
npm run clear:chi_bo
# hoặc
node clear_collections.js chi_bo
```

**Xóa Đảng bộ:**

```powershell
npm run clear:dang_bo
# hoặc
node clear_collections.js dang_bo
```

**Xóa tất cả (ngoại trừ admin config):**

```powershell
npm run clear:all
# hoặc
node clear_collections.js all
```

**Lưu ý:** Script sẽ yêu cầu xác nhận trước khi xóa

```
⚠️  Are you sure? This cannot be undone! (yes/no): yes
🗑️  Deleting collection: chi_bo
   Deleted 100 documents...
   Deleted 200 documents...
✅ Collection cleared: chi_bo (200 documents deleted)
```

---

## 🔄 Quy Trình Upload Dữ Liệu

### Lần Đầu Tiên

```powershell
# 1. Xem trước dữ liệu
npm run preview "D:\path\to\file.xlsx"

# 2. Upload dữ liệu
npm run upload "D:\path\to\file.xlsx"

# 3. Xác minh trong Firebase Console
# → Firestore Database → Xem collections chi_bo, dang_bo, config
```

### Cập Nhật Dữ Liệu

```powershell
# 1. (Tùy chọn) Xóa dữ liệu cũ
npm run clear:chi_bo

# 2. Upload dữ liệu mới
npm run upload "D:\path\to\new_file.xlsx"

# Lưu ý: Admin config KHÔNG bị xóa, vẫn giữ lại
```

---

## 🔐 Bảo Mật

### File Service Account Key

- 🚫 **Không** commit vào Git
- 🔒 Giữ bảo mật như password
- 📍 Lưu tại: `d:\NHS_APP\firebase-admin-key.json`
- ✅ Đã thêm vào `.gitignore`

### Firebase Security Rules

Trước khi upload dữ liệu, kiểm tra Firestore Security Rules:

**Tạm thời cho phép (KHI TEST):**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Bảo mật (PRODUCTION):**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin config - chỉ admin được sửa
    match /config/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && isAdmin();
    }

    // Data collections - chỉ admin được sửa
    match /{collection=**}/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && isAdmin();
    }
  }
}

function isAdmin() {
  return request.auth.token.email in ['admin@nhs.vn', 'admin@gmail.com'];
}
```

---

## ⚠️ Troubleshooting

### ❌ "firebase-admin-key.json not found"

**Giải pháp:**

1. Mở [Firebase Console](https://console.firebase.google.com)
2. Vào Project Settings → Service Accounts
3. Click "Generate New Private Key"
4. Lưu file vào: `d:\NHS_APP\firebase-admin-key.json`

### ❌ "PERMISSION_DENIED" từ Firestore

**Giải pháp:**

1. Kiểm tra Firestore Security Rules
2. Tạm thời set rules thành `allow read, write: if true;`
3. Thử upload lại
4. Sau khi upload, khôi phục rules bảo mật

### ❌ "ENOENT: no such file or directory"

**Giải pháp:**

- Dùng đường dẫn tuyệt đối
- Windows: `D:\path\to\file.xlsx` hoặc `D:/path/to/file.xlsx`
- Kiểm tra file có tồn tại không

### ❌ "No Chi bộ data found"

**Giải pháp:**

1. Kiểm tra tên sheet và cột trong Excel
2. Thử dùng `npm run preview` để xem cấu trúc file
3. Chắc chắn file Excel không empty

### ❌ "Node command not found"

**Giải pháp:**

1. Cài Node.js từ [nodejs.org](https://nodejs.org)
2. Khởi động lại PowerShell
3. Kiểm tra: `node --version`

---

## 💡 Mẹo

1. **Tự động hóa**: Thêm script vào Task Scheduler (Windows) để chạy định kỳ
2. **Backup**: Trước khi xóa dữ liệu lớn, export từ Firebase Console
3. **Logs**: Kiểm tra Firebase Console → Logs để debug
4. **Batch**: Script tự động chia thành batch để xử lý dữ liệu lớn

---

## 📞 Hỗ Trợ

Nếu gặp lỗi:

1. Kiểm tra console output
2. Xem Firebase Console Logs
3. Verify Firebase Security Rules
4. Thử script `preview_excel.js` trước

---

## 📦 Phiên Bản

- **Version**: 1.0.0
- **Node**: ≥14.0.0
- **Dependencies**: firebase-admin, xlsx

---

**Cập nhật lần cuối:** 2025-10-28
