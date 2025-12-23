const admin = require("firebase-admin");
const XLSX = require("xlsx");
const path = require("path");

// Initialize Firebase Admin
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function fullReimport() {
  try {
    console.log("🔄 BẮT ĐẦU IMPORT LẠI TOÀN BỘ DỮ LIỆU\n");

    // Bước 1: Xóa tất cả dữ liệu cũ
    console.log("🗑️  Bước 1: Xóa tất cả tổ chức cũ...");
    const oldSnapshot = await db.collection("to_chuc_dang").get();
    console.log(`   Tìm thấy ${oldSnapshot.size} tổ chức cũ`);

    let batch = db.batch();
    let count = 0;

    oldSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
      if (count % 500 === 0) {
        console.log(`   Đã xóa ${count}/${oldSnapshot.size}...`);
      }
    });

    await batch.commit();
    console.log(`✅ Đã xóa ${count} tổ chức cũ\n`);

    // Bước 2: Import dữ liệu mới từ Excel
    console.log("📖 Bước 2: Đọc file Excel...");
    const filePath = path.join(
      __dirname,
      "Danh_Sach_To_Chuc_Dang_2025-12-16 đã sửa.xlsx"
    );
    const workbook = XLSX.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const data = XLSX.utils.sheet_to_json(worksheet);

    console.log(`✅ Đọc được ${data.length} dòng từ Excel\n`);
    console.log("💾 Bước 3: Import dữ liệu mới vào Firestore...\n");

    let successCount = 0;
    const allPromises = [];

    // ⭐ THAY ĐỔI: Dùng Promise.all thay vì batch để tránh lỗi
    for (let i = 0; i < data.length; i++) {
      const row = data[i];

      const stt = row["STT"];
      if (!stt) {
        console.log(`⚠️  Bỏ qua dòng ${i + 1}: Không có STT`);
        continue;
      }

      const docRef = db.collection("to_chuc_dang").doc();

      const orgData = {
        id: docRef.id,
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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Thêm promise vào array
      allPromises.push(docRef.set(orgData));

      successCount++;
      console.log(
        `✅ [${successCount}/${data.length}] STT ${stt}: ${orgData.name}`
      );

      // Commit mỗi 50 docs để tránh quá tải
      if (allPromises.length >= 50) {
        await Promise.all(allPromises);
        console.log(`\n💾 Đã lưu ${allPromises.length} documents\n`);
        allPromises.length = 0; // Clear array
      }
    }

    // Commit các documents còn lại
    if (allPromises.length > 0) {
      await Promise.all(allPromises);
      console.log(`\n💾 Đã lưu ${allPromises.length} documents cuối cùng\n`);
    }
    console.log("\n" + "=".repeat(70));
    console.log("✅ HOÀN THÀNH IMPORT!");
    console.log("=".repeat(70));

    // ⏱️ Đợi 5 giây để Firestore đồng bộ hoàn toàn
    console.log("\n⏱️  Đang đợi Firestore đồng bộ (5 giây)...");
    await new Promise((resolve) => setTimeout(resolve, 5000));
    console.log("✅ Tiếp tục kiểm tra...\n");

    // Kiểm tra kết quả
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

    console.log("📈 THỐNG KÊ SAU KHI IMPORT:");
    console.log(`   - Tổng số tổ chức: ${finalSnapshot.size}`);
    console.log(`   - Tổng đảng viên: ${totalMembers}`);
    console.log(`   - Đảng viên chính thức: ${officialMembers}`);
    console.log(`   - Đảng viên dự bị: ${probationaryMembers}`);
    console.log("=".repeat(70));

    const allCorrect =
      finalSnapshot.size === 173 &&
      totalMembers === 4905 &&
      officialMembers === 4597 &&
      probationaryMembers === 308;

    if (allCorrect) {
      console.log("\n🎉 TẤT CẢ SỐ LIỆU CHÍNH XÁC! ✅");
    } else {
      console.log("\n⚠️  CÓ SỐ LIỆU CHƯA KHỚP:");
      if (finalSnapshot.size !== 173)
        console.log(`   - Tổ chức: ${finalSnapshot.size} (cần 173)`);
      if (totalMembers !== 4905)
        console.log(`   - Tổng đảng viên: ${totalMembers} (cần 4905)`);
      if (officialMembers !== 4597)
        console.log(`   - Chính thức: ${officialMembers} (cần 4597)`);
      if (probationaryMembers !== 308)
        console.log(`   - Dự bị: ${probationaryMembers} (cần 308)`);
    }

    process.exit(0);
  } catch (error) {
    console.error("\n❌ LỖI:", error);
    process.exit(1);
  }
}

fullReimport();
