const admin = require("firebase-admin");
const XLSX = require("xlsx");
const fs = require("fs");

// Initialize Firebase Admin
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function exportOrganizationsToExcel() {
  try {
    console.log("📊 Đang lấy dữ liệu tổ chức đảng từ Firestore...");

    const snapshot = await db
      .collection("to_chuc_dang")
      .orderBy("stt", "asc")
      .get();

    console.log(`✅ Tìm thấy ${snapshot.size} tổ chức đảng`);

    const organizations = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      organizations.push({
        STT: data.stt || "",
        "Tên Tổ Chức": data.name || "",
        "Loại Hình": data.type || "",
        "Tổng Đảng Viên": data.totalMembers || 0,
        "Đảng Viên Chính Thức": data.officialMembers || 0,
        "Đảng Viên Dự Bị": data.probationaryMembers || 0,
        "Ủy Viên Phụ Trách": data.officerInCharge || "",
        "Chức Vụ UV Phụ Trách": data.officerPosition || "",
        "ĐT UV Phụ Trách": data.officerPhone || "",
        "Bí Thư": data.secretary || "",
        "ĐT Bí Thư": data.secretaryPhone || "",
        "Ghi Chú": data.notes || "",
        "Ngày Tạo": data.createdAt
          ? new Date(data.createdAt.seconds * 1000).toLocaleDateString("vi-VN")
          : "",
        "Ngày Cập Nhật": data.updatedAt
          ? new Date(data.updatedAt.seconds * 1000).toLocaleDateString("vi-VN")
          : "",
      });
    });

    // Tạo workbook và worksheet
    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.json_to_sheet(organizations);

    // Thiết lập độ rộng cột
    const colWidths = [
      { wch: 5 }, // STT
      { wch: 40 }, // Tên Tổ Chức
      { wch: 20 }, // Loại Hình
      { wch: 15 }, // Tổng Đảng Viên
      { wch: 18 }, // Đảng Viên Chính Thức
      { wch: 18 }, // Đảng Viên Dự Bị
      { wch: 25 }, // Ủy Viên Phụ Trách
      { wch: 25 }, // Chức Vụ
      { wch: 15 }, // ĐT UV Phụ Trách
      { wch: 25 }, // Bí Thư
      { wch: 15 }, // ĐT Bí Thư
      { wch: 30 }, // Ghi Chú
      { wch: 15 }, // Ngày Tạo
      { wch: 15 }, // Ngày Cập Nhật
    ];
    ws["!cols"] = colWidths;

    // Thêm worksheet vào workbook
    XLSX.utils.book_append_sheet(wb, ws, "Danh Sách Tổ Chức Đảng");

    // Tạo sheet thống kê tổng hợp
    const stats = {
      "Tổng số tổ chức": organizations.length,
      "Tổng đảng viên": organizations.reduce(
        (sum, org) => sum + (org["Tổng Đảng Viên"] || 0),
        0
      ),
      "Tổng đảng viên chính thức": organizations.reduce(
        (sum, org) => sum + (org["Đảng Viên Chính Thức"] || 0),
        0
      ),
      "Tổng đảng viên dự bị": organizations.reduce(
        (sum, org) => sum + (org["Đảng Viên Dự Bị"] || 0),
        0
      ),
    };

    const statsData = Object.entries(stats).map(([key, value]) => ({
      "Chỉ Tiêu": key,
      "Số Lượng": value,
    }));

    const ws_stats = XLSX.utils.json_to_sheet(statsData);
    ws_stats["!cols"] = [{ wch: 30 }, { wch: 15 }];
    XLSX.utils.book_append_sheet(wb, ws_stats, "Thống Kê Tổng Hợp");

    // Xuất file
    const fileName = `Danh_Sach_To_Chuc_Dang_${
      new Date().toISOString().split("T")[0]
    }.xlsx`;
    const filePath = `./${fileName}`;

    XLSX.writeFile(wb, filePath);

    console.log("\n✅ XUẤT FILE THÀNH CÔNG!");
    console.log(`📁 File đã được lưu tại: ${filePath}`);
    console.log("\n📊 THỐNG KÊ:");
    console.log(`   - Tổng số tổ chức: ${stats["Tổng số tổ chức"]}`);
    console.log(`   - Tổng đảng viên: ${stats["Tổng đảng viên"]}`);
    console.log(
      `   - Đảng viên chính thức: ${stats["Tổng đảng viên chính thức"]}`
    );
    console.log(`   - Đảng viên dự bị: ${stats["Tổng đảng viên dự bị"]}`);

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    process.exit(1);
  }
}

exportOrganizationsToExcel();
