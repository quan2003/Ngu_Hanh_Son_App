const admin = require("firebase-admin");
const XLSX = require("xlsx");
const path = require("path");

// Initialize Firebase Admin - chỉ khởi tạo 1 lần
if (admin.apps.length === 0) {
  const serviceAccount = require("../firebase-admin-key.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function simpleImport() {
  try {
    console.log("🔄 IMPORT DỮ LIỆU TỪ EXCEL\n");

    // Đọc file Excel
    console.log("📖 Đọc file Excel...");
    const filePath = path.join(
      __dirname,
      "Danh_Sach_To_Chuc_Dang_2025-12-16 đã sửa.xlsx"
    );
    const workbook = XLSX.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const data = XLSX.utils.sheet_to_json(worksheet);

    console.log(`✅ Đọc được ${data.length} dòng\n`);

    console.log("💾 Import từng tổ chức...\n");

    let successCount = 0;

    for (let i = 0; i < data.length; i++) {
      const row = data[i];

      const stt = row["STT"];
      if (!stt) {
        console.log(`⚠️  Bỏ qua dòng ${i + 1}: Không có STT`);
        continue;
      }

      const orgData = {
        stt: Number(stt),
        name: row["Tên Tổ Chức"] || "",
        type: row["Loại Hình"] || "",
        totalMembers: Number(row["Tổng Đảng Viên"] || 0),
        officialMembers: Number(row["Đảng Viên Chính Thức"] || 0),
        probationaryMembers: Number(row["Đảng Viên Dự Bị"] || 0),
        officerInCharge: row["Ủy Viên Phụ Trách"] || "",
        officerPosition: row["Chức Vụ UV Phụ Trách"] || "",
        officerPhone: row["ĐT UV Phụ Trách"] || "",
        secretary: row["Bí Thư"] || "",
        secretaryPhone: row["ĐT Bí Thư"] || "",
        notes: row["Ghi Chú"] || "",
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      };

      // Add document
      await db.collection("to_chuc_dang").add(orgData);

      successCount++;
      console.log(`✅ [${successCount}] STT ${stt}: ${orgData.name}`);
    }

    console.log("\n" + "=".repeat(70));
    console.log(`✅ Đã import ${successCount} tổ chức thành công!`);
    console.log("=".repeat(70));

    // Verify
    console.log("\n🔍 Xác minh dữ liệu...");
    const snapshot = await db.collection("to_chuc_dang").get();

    let totalMembers = 0;
    let officialMembers = 0;
    let probationaryMembers = 0;

    snapshot.forEach((doc) => {
      const data = doc.data();
      totalMembers += data.totalMembers || 0;
      officialMembers += data.officialMembers || 0;
      probationaryMembers += data.probationaryMembers || 0;
    });

    console.log("\n📈 KẾT QUẢ CUỐI CÙNG:");
    console.log("=".repeat(70));
    console.log(
      `   - Tổng số tổ chức: ${snapshot.size} ${
        snapshot.size === 173 ? "✅" : "❌"
      }`
    );
    console.log(
      `   - Tổng đảng viên: ${totalMembers} ${
        totalMembers === 4905 ? "✅" : "❌"
      }`
    );
    console.log(
      `   - Đảng viên chính thức: ${officialMembers} ${
        officialMembers === 4597 ? "✅" : "❌"
      }`
    );
    console.log(
      `   - Đảng viên dự bị: ${probationaryMembers} ${
        probationaryMembers === 308 ? "✅" : "❌"
      }`
    );
    console.log("=".repeat(70));

    process.exit(0);
  } catch (error) {
    console.error("\n❌ LỖI:", error);
    process.exit(1);
  }
}

simpleImport();
