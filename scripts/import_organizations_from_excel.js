const admin = require("firebase-admin");
const XLSX = require("xlsx");
const path = require("path");

// Initialize Firebase Admin
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function importOrganizationsFromExcel() {
  try {
    const filePath = path.join(
      __dirname,
      "Danh_Sach_To_Chuc_Dang_2025-12-16 đã sửa.xlsx"
    );

    console.log("📖 Đang đọc file Excel...");
    console.log("📁 File:", filePath);

    const workbook = XLSX.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];

    // Chuyển đổi worksheet thành JSON
    const data = XLSX.utils.sheet_to_json(worksheet);

    console.log(`✅ Đọc được ${data.length} tổ chức từ Excel`);
    console.log("\n🔄 Bắt đầu cập nhật dữ liệu vào Firestore...\n");

    let successCount = 0;
    let errorCount = 0;

    // Lấy tất cả tổ chức hiện tại để tìm document ID theo STT
    const snapshot = await db.collection("to_chuc_dang").get();
    const existingOrgs = {};
    snapshot.forEach((doc) => {
      const data = doc.data();
      if (data.stt) {
        existingOrgs[data.stt] = doc.id;
      }
    });

    console.log(
      `📊 Tìm thấy ${snapshot.size} tổ chức hiện có trong Firestore\n`
    );

    // Batch update
    const batchSize = 500;
    let batch = db.batch();
    let operationCount = 0;

    for (let i = 0; i < data.length; i++) {
      const row = data[i];

      try {
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
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Nếu tổ chức đã tồn tại, update; nếu không, tạo mới
        let docRef;
        if (existingOrgs[stt]) {
          docRef = db.collection("to_chuc_dang").doc(existingOrgs[stt]);
          batch.update(docRef, orgData);
          console.log(
            `✏️  [${i + 1}/${data.length}] Cập nhật STT ${stt}: ${orgData.name}`
          );
        } else {
          docRef = db.collection("to_chuc_dang").doc();
          orgData.createdAt = admin.firestore.FieldValue.serverTimestamp();
          batch.set(docRef, orgData);
          console.log(
            `➕ [${i + 1}/${data.length}] Tạo mới STT ${stt}: ${orgData.name}`
          );
        }

        operationCount++;
        successCount++;

        // Commit batch khi đạt batchSize hoặc hết data
        if (operationCount === batchSize || i === data.length - 1) {
          await batch.commit();
          console.log(`\n💾 Đã commit batch (${operationCount} operations)\n`);
          batch = db.batch();
          operationCount = 0;
        }
      } catch (error) {
        errorCount++;
        console.error(`❌ Lỗi dòng ${i + 1}:`, error.message);
      }
    }

    console.log("\n" + "=".repeat(60));
    console.log("✅ HOÀN THÀNH!");
    console.log("=".repeat(60));
    console.log(`📊 Tổng số: ${data.length} tổ chức`);
    console.log(`✅ Thành công: ${successCount}`);
    console.log(`❌ Lỗi: ${errorCount}`);
    console.log("=".repeat(60) + "\n");

    // Thống kê sau khi import
    const finalSnapshot = await db.collection("to_chuc_dang").get();
    let totalMembers = 0;
    let officialMembers = 0;
    let probationaryMembers = 0;

    finalSnapshot.forEach((doc) => {
      const data = doc.data();
      totalMembers += data.totalMembers || 0;
      officialMembers += data.officialMembers || 0;
      probationaryMembers += data.probationaryMembers || 0;
    });

    console.log("📈 THỐNG KÊ SAU KHI CẬP NHẬT:");
    console.log(`   - Tổng số tổ chức: ${finalSnapshot.size}`);
    console.log(`   - Tổng đảng viên: ${totalMembers}`);
    console.log(`   - Đảng viên chính thức: ${officialMembers}`);
    console.log(`   - Đảng viên dự bị: ${probationaryMembers}`);

    process.exit(0);
  } catch (error) {
    console.error("\n❌ LỖI NGHIÊM TRỌNG:", error);
    process.exit(1);
  }
}

importOrganizationsFromExcel();
