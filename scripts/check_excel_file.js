const XLSX = require("xlsx");
const path = require("path");

async function checkExcelFile() {
  try {
    const filePath = path.join(
      __dirname,
      "Danh_Sach_To_Chuc_Dang_2025-12-16 đã sửa.xlsx"
    );

    console.log("📖 Đang đọc file Excel...");
    console.log("📁 File:", filePath);
    console.log("");

    const workbook = XLSX.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];

    // Chuyển đổi worksheet thành JSON
    const data = XLSX.utils.sheet_to_json(worksheet);

    console.log("=".repeat(70));
    console.log("📊 THỐNG KÊ FILE EXCEL");
    console.log("=".repeat(70));

    let totalOrgs = 0;
    let totalMembers = 0;
    let officialMembers = 0;
    let probationaryMembers = 0;
    let rowsWithoutSTT = 0;

    data.forEach((row, index) => {
      if (row["STT"]) {
        totalOrgs++;
        totalMembers += Number(row["Tổng Đảng Viên"] || 0);
        officialMembers += Number(row["Đảng Viên Chính Thức"] || 0);
        probationaryMembers += Number(row["Đảng Viên Dự Bị"] || 0);
      } else {
        rowsWithoutSTT++;
        console.log(
          `⚠️  Dòng ${index + 2} không có STT: ${row["Tên Tổ Chức"] || "N/A"}`
        );
      }
    });

    console.log(`\n📋 Tổng số dòng trong file: ${data.length}`);
    console.log(`✅ Số tổ chức có STT: ${totalOrgs}`);
    console.log(`⚠️  Số dòng không có STT: ${rowsWithoutSTT}`);
    console.log("");
    console.log(`👥 Tổng đảng viên: ${totalMembers}`);
    console.log(`🎖️  Đảng viên chính thức: ${officialMembers}`);
    console.log(`📋 Đảng viên dự bị: ${probationaryMembers}`);
    console.log("=".repeat(70));

    console.log("\n🔍 SO SÁNH VỚI YÊU CẦU:");
    console.log("=".repeat(70));
    console.log(
      `Số tổ chức: ${totalOrgs} ${totalOrgs === 173 ? "✅" : "❌"} (cần 173)`
    );
    console.log(
      `Tổng đảng viên: ${totalMembers} ${
        totalMembers === 4905 ? "✅" : "❌"
      } (cần 4905)`
    );
    console.log(
      `Chính thức: ${officialMembers} ${
        officialMembers === 4597 ? "✅" : "❌"
      } (cần 4597)`
    );
    console.log(
      `Dự bị: ${probationaryMembers} ${
        probationaryMembers === 308 ? "✅" : "❌"
      } (cần 308)`
    );
    console.log("=".repeat(70));

    // Hiển thị 10 tổ chức đầu tiên
    console.log("\n📝 10 TỔ CHỨC ĐẦU TIÊN:");
    console.log("=".repeat(70));
    data.slice(0, 10).forEach((row, index) => {
      console.log(`${index + 1}. STT ${row["STT"]}: ${row["Tên Tổ Chức"]}`);
      console.log(
        `   → ${row["Tổng Đảng Viên"]} đảng viên (${row["Đảng Viên Chính Thức"]} chính thức, ${row["Đảng Viên Dự Bị"]} dự bị)`
      );
    });

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    process.exit(1);
  }
}

checkExcelFile();
