const admin = require("firebase-admin");

// Initialize Firebase Admin
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function verifyStats() {
  try {
    console.log("📊 Kiểm tra số liệu hiện tại...\n");

    const snapshot = await db
      .collection("to_chuc_dang")
      .orderBy("stt", "asc")
      .get();

    let totalOrgs = 0;
    let totalMembers = 0;
    let officialMembers = 0;
    let probationaryMembers = 0;

    const orgsWithMembers = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      totalOrgs++;

      const tm = data.totalMembers || 0;
      const om = data.officialMembers || 0;
      const pm = data.probationaryMembers || 0;

      totalMembers += tm;
      officialMembers += om;
      probationaryMembers += pm;

      if (tm > 0) {
        orgsWithMembers.push({
          stt: data.stt,
          name: data.name,
          total: tm,
          official: om,
          probationary: pm,
        });
      }
    });

    console.log("=".repeat(70));
    console.log("📈 THỐNG KÊ HIỆN TẠI:");
    console.log("=".repeat(70));
    console.log(`   - Tổng số tổ chức: ${totalOrgs}`);
    console.log(`   - Tổng đảng viên: ${totalMembers}`);
    console.log(`   - Đảng viên chính thức: ${officialMembers}`);
    console.log(`   - Đảng viên dự bị: ${probationaryMembers}`);
    console.log("=".repeat(70));

    console.log("\n📋 SỐ LIỆU MONG MUỐN (theo bạn cung cấp):");
    console.log("=".repeat(70));
    console.log(`   - Tổng số tổ chức: 173`);
    console.log(`   - Tổng đảng viên: 4905`);
    console.log(`   - Đảng viên chính thức: 4597`);
    console.log(`   - Đảng viên dự bị: 308`);
    console.log("=".repeat(70));

    console.log("\n🔍 CHÊNH LỆCH:");
    console.log("=".repeat(70));
    console.log(`   - Tổ chức: ${173 - totalOrgs} (${totalOrgs} → 173)`);
    console.log(
      `   - Tổng đảng viên: ${4905 - totalMembers} (${totalMembers} → 4905)`
    );
    console.log(
      `   - Chính thức: ${4597 - officialMembers} (${officialMembers} → 4597)`
    );
    console.log(
      `   - Dự bị: ${308 - probationaryMembers} (${probationaryMembers} → 308)`
    );
    console.log("=".repeat(70));

    console.log("\n📝 Danh sách tổ chức có đảng viên:");
    console.log("=".repeat(70));
    orgsWithMembers.forEach((org, index) => {
      console.log(`${index + 1}. STT ${org.stt}: ${org.name}`);
      console.log(
        `   → ${org.total} đảng viên (${org.official} chính thức, ${org.probationary} dự bị)`
      );
    });

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    process.exit(1);
  }
}

verifyStats();
