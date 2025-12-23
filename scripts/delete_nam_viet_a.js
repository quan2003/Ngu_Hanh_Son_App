const admin = require("firebase-admin");

// Initialize Firebase Admin
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function findAndDeleteNamVietA() {
  try {
    console.log("🔍 Đang tìm Chi bộ Nam Việt Á...\n");

    const snapshot = await db
      .collection("to_chuc_dang")
      .where("name", ">=", "Nam Việt")
      .where("name", "<=", "Nam Việt\uf8ff")
      .get();

    if (snapshot.empty) {
      console.log("⚠️  Không tìm thấy Chi bộ Nam Việt Á");

      // Tìm tất cả tổ chức có chứa "Nam Việt" hoặc "Việt Á"
      console.log("\n🔍 Tìm kiếm tổng quát...");
      const allSnapshot = await db.collection("to_chuc_dang").get();

      let found = false;
      allSnapshot.forEach((doc) => {
        const data = doc.data();
        if (
          data.name &&
          (data.name.toLowerCase().includes("nam việt") ||
            data.name.toLowerCase().includes("việt á") ||
            data.name.toLowerCase().includes("nam viet"))
        ) {
          console.log(`\n📋 Tìm thấy:`);
          console.log(`   ID: ${doc.id}`);
          console.log(`   STT: ${data.stt}`);
          console.log(`   Tên: ${data.name}`);
          console.log(`   Loại: ${data.type}`);
          found = true;
        }
      });

      if (!found) {
        console.log("✅ Không tìm thấy tổ chức nào liên quan đến Nam Việt Á");
      }
    } else {
      console.log(`✅ Tìm thấy ${snapshot.size} tổ chức:\n`);

      const batch = db.batch();
      let deleteCount = 0;

      snapshot.forEach((doc) => {
        const data = doc.data();
        console.log(`📋 Tổ chức sẽ bị XÓA:`);
        console.log(`   ID: ${doc.id}`);
        console.log(`   STT: ${data.stt}`);
        console.log(`   Tên: ${data.name}`);
        console.log(`   Loại: ${data.type}`);
        console.log(`   Đảng viên: ${data.totalMembers}\n`);

        batch.delete(doc.ref);
        deleteCount++;
      });

      if (deleteCount > 0) {
        await batch.commit();
        console.log(`✅ Đã xóa ${deleteCount} tổ chức thành công!\n`);
      }
    }

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

    console.log("📈 THỐNG KÊ SAU KHI XÓA:");
    console.log(`   - Tổng số tổ chức: ${finalSnapshot.size}`);
    console.log(`   - Tổng đảng viên: ${totalMembers}`);
    console.log(`   - Đảng viên chính thức: ${officialMembers}`);
    console.log(`   - Đảng viên dự bị: ${probationaryMembers}`);

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    process.exit(1);
  }
}

findAndDeleteNamVietA();
