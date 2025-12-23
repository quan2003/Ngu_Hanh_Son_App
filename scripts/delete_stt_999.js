const admin = require("firebase-admin");

// Initialize Firebase Admin
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteSTT999Organizations() {
  try {
    console.log("🔍 Đang tìm tất cả tổ chức có STT 999...\n");

    const snapshot = await db
      .collection("to_chuc_dang")
      .where("stt", "==", 999)
      .get();

    if (snapshot.empty) {
      console.log("✅ Không tìm thấy tổ chức nào có STT 999");
      process.exit(0);
    }

    console.log(`📋 Tìm thấy ${snapshot.size} tổ chức có STT 999:\n`);

    const batch = db.batch();
    let deleteCount = 0;

    snapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`❌ Sẽ XÓA:`);
      console.log(`   ID: ${doc.id}`);
      console.log(`   STT: ${data.stt}`);
      console.log(`   Tên: ${data.name}`);
      console.log(`   Loại: ${data.type}`);
      console.log(
        `   Đảng viên: ${data.totalMembers} (${data.officialMembers} chính thức, ${data.probationaryMembers} dự bị)\n`
      );

      batch.delete(doc.ref);
      deleteCount++;
    });

    await batch.commit();
    console.log(`✅ Đã xóa ${deleteCount} tổ chức thành công!\n`);

    // Thống kê sau khi xóa
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

    console.log("=".repeat(60));
    console.log("📈 THỐNG KÊ SAU KHI XÓA:");
    console.log("=".repeat(60));
    console.log(`   - Tổng số tổ chức: ${finalSnapshot.size}`);
    console.log(`   - Tổng đảng viên: ${totalMembers}`);
    console.log(`   - Đảng viên chính thức: ${officialMembers}`);
    console.log(`   - Đảng viên dự bị: ${probationaryMembers}`);
    console.log("=".repeat(60));

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    process.exit(1);
  }
}

deleteSTT999Organizations();
