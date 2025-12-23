/**
 * Script to update organization order based on actual database names
 * Matched with the official order list
 */

const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

// Initialize Firebase Admin (check if already initialized)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// Exact mapping based on actual database names and requested order
const organizationOrder = {
  // STT 1-13: Đảng bộ cơ sở và Chi bộ chính
  "Đảng bộ (cơ sở) Các cơ quan Đảng ": 1,
  "Đảng bộ (cơ sở) Ủy ban nhân dân phường": 2,
  "Đảng bộ (cơ sở) Trung tâm Y tế khu vực Ngũ Hành Sơn": 3,
  "Chi bộ (cơ sở) Trường THPT Ngũ Hành Sơn": 4,
  "Chi bộ (cơ sở) Trường THPT Võ Chí Công": 5,
  "Chi bộ (cơ sở) Trường cấp I, II, III Hermann Gmeiner ": 6,
  "Chi bộ (cơ sở) Trường Cao đẳng Du lịch Đà Nẵng ": 7,
  "Chi bộ (cơ sở) Làng Trẻ em SOS ": 8,
  "Chi bộ (cơ sở) Công ty Cổ phần Xây lắp thủy sản Việt Nam ": 9,
  "Chi bộ (cơ sở) Công ty Cổ phần Khu du lịch Bắc Mỹ An": 10,
  "Chi bộ (cơ sở) Công ty trách nhiệm hữu hạn Du lịch Thương mại Phú An Thịnh": 11,
  "Chi bộ (cơ sở) Công ty Cổ phần Thiên Long Châu ": 12,
  "Chi bộ Trạm Y tế phường": 13,

  // STT 14-16: Các công ty
  "Chi bộ Công ty trách nhiệm hữu hạn thương mại dịch vụ Buổi sáng tuyệt vời": 14,
  "Chi bộ Công ty trách nhiệm hữu hạn Xây dựng và Thương mại số 126": 15,
  "Chi bộ Công ty trách nhiệm hữu hạn Một Thành viên Nhật Bích": 16,

  // STT 17-20: Trường THCS
  "Chi bộ Trường Trung học cơ sở Lê Lợi": 17,
  "Chi bộ Trường Trung học cơ sở Trần Đại Nghĩa": 18,
  "Chi bộ Trường Trung học cơ sở Huỳnh Bá Chánh": 19,
  "Chi bộ Trường Trung học cơ sở Nguyễn Bỉnh Khiêm": 20,

  // STT 21-28: Trường Tiểu học
  "Chi bộ Trường Tiểu học Lê Lai": 21,
  "Chi bộ Trường Tiểu học Lê Bá Trinh": 22,
  "Chi bộ Trường Tiểu học Trần Quang Diệu": 23,
  "Chi bộ Trường Tiểu học Nguyễn Duy Trinh": 24,
  "Chi bộ Trường Tiểu học Lê Văn Hiến": 25,
  "Chi bộ Trường Tiểu học Mai Đăng Chơn": 26,
  "Chi bộ Trường Tiểu học Phạm Hồng Thái": 27,
  "Chi bộ Trường Tiểu học Tô Hiến Thành": 28,

  // STT 29-36: Trường Mầm non
  "Chi bộ Trường Mầm non Bạch Dương": 29,
  "Chi bộ Trường Mầm non Sen Hồng": 30,
  "Chi bộ Trường Mầm non Ngọc Lan": 31,
  // Missing: 'MN Ngôi Sao Nhỏ': 32 (not in database)
  " Chi bộ Trường Mầm non Hoàng Lan": 33,
  "Chi bộ Trường Mầm non Tân Trà": 34,
  "Chi bộ Trường Mầm non Vàng Anh": 35,
  "Chi bộ Trường Mầm non Hoàng Anh": 36,

  // STT 37-79: Chi bộ An Thượng và Mỹ Đa Đông, Mỹ Đa Tây
  "Chi bộ 1 An Thượng (khu vực Mỹ An trước đây)": 37,
  "Chi bộ 2 An Thượng (khu vực Mỹ An trước đây)": 38,
  "Chi bộ 3 An Thượng (khu vực Mỹ An trước đây)": 39,
  "Chi bộ 4 An Thượng (khu vực Mỹ An trước đây)": 40,
  "Chi bộ 5 An Thượng (khu vực Mỹ An trước đây)": 41,
  "Chi bộ 6 An Thượng (khu vực Mỹ An trước đây)": 42,
  "Chi bộ 7 An Thượng (khu vực Mỹ An trước đây)": 43,
  "Chi bộ 8 An Thượng (khu vực Mỹ An trước đây)": 44,
  "Chi bộ 9 An Thượng (khu vực Mỹ An trước đây)": 45,
  "Chi bộ 10-11 An Thượng (khu vực Mỹ An trước đây)": 46,
  "Chi bộ 12 An Thượng (khu vực Mỹ An trước đây)": 47,
  "Chi bộ 13 An Thượng (khu vực Mỹ An trước đây)": 48,
  "Chi bộ 14 An Thượng (khu vực Mỹ An trước đây)": 49,
  "Chi bộ 15-16-17 An Thượng (khu vực Mỹ An trước đây)": 50,
  "Chi bộ 18 An Thượng (khu vực Mỹ An trước đây)": 51,
  "Chi bộ 19 An Thượng (khu vực Mỹ An trước đây)": 52,
  "Chi bộ 20-21 An Thượng (khu vực Mỹ An trước đây)": 53,
  "Chi bộ 22 An Thượng (khu vực Mỹ An trước đây)": 54,
  "Chi bộ 23 An Thượng (khu vực Mỹ An trước đây)": 55,
  "Chi bộ 24-25 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 56,
  "Chi bộ 26-27 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 57,
  "Chi bộ 28 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 58,
  "Chi bộ 29 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 59,
  "Chi bộ 30 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 60,
  "Chi bộ 31 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 61,
  "Chi bộ 32 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 62,
  "Chi bộ 33 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 63,
  "Chi bộ 34-35 Mỹ Đa Đông (khu vực Mỹ An trước đây)     ": 64,
  "Chi bộ 36 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 65,
  "Chi bộ 37 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 66,
  "Chi bộ 38 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 67,
  "Chi bộ 39 Mỹ Đa Đông (khu vực Mỹ An trước đây)": 68,
  " Chi bộ 40 An Thượng (khu vực Mỹ An trước đây)": 69,
  "Chi bộ 41-42 An Thượng (khu vực Mỹ An trước đây)": 70,
  "Chi bộ 43-44-45 An Thượng (khu vực Mỹ An trước đây)": 71,
  "Chi bộ 46 An Thượng (khu vực Mỹ An trước đây)": 72,
  "Chi bộ 47-48 An Thượng (khu vực Mỹ An trước đây)": 73,
  "Chi bộ 49-50-52 Mỹ Đa Tây (khu vực Mỹ An trước đây)": 74,
  "Chi bộ 51 Mỹ Đa Tây (khu vực Mỹ An trước đây)": 75,
  "Chi bộ 53 Mỹ Đa Tây (khu vực Mỹ An trước đây)": 76,
  "Chi bộ 54 Mỹ Đa Tây (khu vực Mỹ An trước đây)": 77,
  "Chi bộ 55 Mỹ Đa Tây (khu vực Mỹ An trước đây)": 78,
  "Chi bộ 56-57 Mỹ Đa Tây (khu vực Mỹ An trước đây)": 79,

  // STT 80-110: Chi bộ Mỹ Đa Đông, Mỹ Đa Tây, Đa Mặn (khu vực Khuê Mỹ)
  "Chi bộ Mỹ Đa Đông 1 (khu vực Khuê Mỹ trước đây)": 80,
  "Chi bộ Mỹ Đa Đông 1A (khu vực Khuê Mỹ trước đây)": 81,
  "Chi bộ Mỹ Đa Đông 2 (khu vực Khuê Mỹ trước đây)": 82,
  "Chi bộ Mỹ Đa Đông 3 (khu vực Khuê Mỹ trước đây)": 83,
  "Chi bộ Mỹ Đa Đông 3A (khu vực Khuê Mỹ trước đây)": 84,
  "Chi bộ Mỹ Đa Đông 4 (khu vực Khuê Mỹ trước đây)": 85,
  "Chi bộ Mỹ Đa Đông 5 (khu vực Khuê Mỹ trước đây)": 86,
  "Chi bộ Mỹ Đa Tây 1 (khu vực Khuê Mỹ trước đây)": 87,
  "Chi bộ Mỹ Đa Tây 1A (khu vực Khuê Mỹ trước đây)": 88,
  "Chi bộ Mỹ Đa Tây 2 (khu vực Khuê Mỹ trước đây)": 89,
  "Chi bộ Mỹ Đa Tây 3 (khu vực Khuê Mỹ trước đây)": 90,
  "Chi bộ Mỹ Đa Tây 4 (khu vực Khuê Mỹ trước đây)": 91,
  "Chi bộ Đa Mặn 1 (khu vực Khuê Mỹ trước đây)": 92,
  "Chi bộ Đa Mặn 2 (khu vực Khuê Mỹ trước đây)": 93,
  "Chi bộ Đa Mặn 2A (khu vực Khuê Mỹ trước đây)": 94,
  "Chi bộ Đa Mặn 3 (khu vực Khuê Mỹ trước đây)": 95,
  "Chi bộ Đa Mặn 3A (khu vực Khuê Mỹ trước đây)": 96,
  "Chi bộ Đa Mặn 3B (khu vực Khuê Mỹ trước đây)": 97,
  "Chi bộ Đa Mặn 3C (khu vực Khuê Mỹ trước đây)": 98,
  "Chi bộ Đa Mặn 4 (khu vực Khuê Mỹ trước đây)": 99,
  "Chi bộ Đa Mặn 4A (khu vực Khuê Mỹ trước đây)": 100,
  "Chi bộ Đa Mặn 5 (khu vực Khuê Mỹ trước đây)": 101,
  "Chi bộ Đa Mặn 6 (khu vực Khuê Mỹ trước đây)": 102,
  "Chi bộ Đa Mặn 7 (khu vực Khuê Mỹ trước đây)": 103,
  "Chi bộ Đa Mặn 8 (khu vực Khuê Mỹ trước đây)": 104,
  "Chi bộ Đa Mặn 8A (khu vực Khuê Mỹ trước đây)": 105,
  "Chi bộ Đa Mặn 9 (khu vực Khuê Mỹ trước đây)": 106,
  "Chi bộ Đa Mặn 9A (khu vực Khuê Mỹ trước đây)": 107,
  "Chi bộ Đa Mặn 10 (khu vực Khuê Mỹ trước đây)": 108,
  "Chi bộ Đa Mặn 11 (khu vực Khuê Mỹ trước đây)": 109,
  "Chi bộ Đa Mặn 12 (khu vực Khuê Mỹ trước đây)": 110,

  // STT 111-149: Chi bộ khu vực Hoà Hải
  "Chi bộ 1A (khu vực Hoà Hải trước đây)": 111,
  "Chi bộ 1B (khu vực Hoà Hải trước đây)": 112,
  "Chi bộ 2A (khu vực Hoà Hải trước đây)": 113,
  "Chi bộ 2B (khu vực Hoà Hải trước đây)": 114,
  "Chi bộ 2C (khu vực Hoà Hải trước đây)": 115,
  "Chi bộ 3A (khu vực Hoà Hải trước đây)": 116,
  "Chi bộ 3B (khu vực Hoà Hải trước đây)": 117,
  "Chi bộ 4A (khu vực Hoà Hải trước đây)": 118,
  "Chi bộ 4B (khu vực Hoà Hải trước đây)": 119,
  "Chi bộ 5 (khu vực Hoà Hải trước đây)": 120,
  "Chi bộ 6 (khu vực Hoà Hải trước đây)": 121,
  "Chi bộ 7 (khu vực Hoà Hải trước đây)": 122,
  "Chi bộ 8A (khu vực Hoà Hải trước đây)": 123,
  "Chi bộ 8B (khu vực Hoà Hải trước đây)": 124,
  "Chi bộ 8C (khu vực Hoà Hải trước đây)": 125,
  "Chi bộ 9A (khu vực Hoà Hải trước đây)": 126,
  "Chi bộ 9B (khu vực Hoà Hải trước đây)": 127,
  "Chi bộ 9C (khu vực Hoà Hải trước đây)": 128,
  "Chi bộ 10A (khu vực Hoà Hải trước đây)": 129,
  "Chi bộ 10B (khu vực Hoà Hải trước đây)": 130,
  "Chi bộ 10C (khu vực Hoà Hải trước đây)": 131,
  "Chi bộ 11 (khu vực Hoà Hải trước đây)": 132,
  " Chi bộ 12 (khu vực Hoà Hải trước đây)": 133,
  "Chi bộ 13A (khu vực Hoà Hải trước đây)": 134,
  "Chi bộ 13B (khu vực Hoà Hải trước đây)": 135,
  "Chi bộ 14 (khu vực Hoà Hải trước đây)": 136,
  "Chi bộ 15 (khu vực Hoà Hải trước đây)": 137,
  "Chi bộ 16A (khu vực Hoà Hải trước đây)": 138,
  "Chi bộ 16B (khu vực Hoà Hải trước đây)": 139,
  "Chi bộ 17A (khu vực Hoà Hải trước đây)": 140,
  "Chi bộ 17B (khu vực Hoà Hải trước đây)": 141,
  "Chi bộ 18A (khu vực Hoà Hải trước đây)": 142,
  "Chi bộ 18B (khu vực Hoà Hải trước đây)": 143,
  "Chi bộ 19A (khu vực Hoà Hải trước đây)": 144,
  "Chi bộ 19B (khu vực Hoà Hải trước đây)": 145,
  "Chi bộ 20A (khu vực Hoà Hải trước đây)": 146,
  "Chi bộ 20B (khu vực Hoà Hải trước đày)": 147,
  "Chi bộ 21A (khu vực Hoà Hải trước đây)": 148,
  "Chi bộ 21B (khu vực Hoà Hải trước đây)": 149,

  // STT 150-171: Chi bộ khu vực Hoà Quý
  "Chi bộ Bình Kỳ (khu vực Hoà Quý trước đây)": 150,
  "Chi bộ Bình Kỳ 1 (khu vực Hoà Quý trước đây)": 151,
  "Chi bộ Bình Kỳ 2A (khu vực Hoà Quý trước đây)": 152,
  "Chi bộ Bình Kỳ 2B (khu vực Hoà Quý trước đây)": 153,
  "Chi bộ Bá Tùng (khu vực Hoà Quý trước đây)": 154,
  "Chi bộ Bá Tùng 1 (khu vực Hoà Quý trước đây)": 155,
  " Chi bộ Khái Tây 2A (khu vực Hoà Quý trước đây)": 156,
  "Chi bộ Khái Tây 2B (khu vực Hoà Quý trước đây)": 157,
  "Chi bộ Khuê Đông (khu vực Hoà Quý trước đây)": 158,
  "Chi bộ Khuê Đông 1 (khu vực Hoà Quý trước đây)": 159,
  "Chi bộ Khuê Đông 2 (khu vực Hoà Quý trước đây)": 160,
  "Chi bộ Khuê Đông 3 (khu vực Hoà Quý trước đây)": 161,
  "Chi bộ Khuê Đông 4 (khu vực Hoà Quý trước đây)": 162,
  "Chi bộ Mân Quang 1 (khu vực Hoà Quý trước đây)": 163,
  "Chi bộ Mân Quang 2 (khu vực Hoà Quý trước đây)": 164,
  "Chi bộ An Lưu (khu vực Hoà Quý trước đây)": 165,
  "Chi bộ Thị An (khu vực Hoà Quý trước đây)": 166,
  "Chi bộ Khái Tây (khu vực Hoà Quý trước đây)": 167,
  "Chi bộ Khái Tây 1 (khu vực Hoà Quý trước đây)": 168,
  "Chi bộ Hải An (khu vực Hoà Quý trước đây)": 169,
  "Chi bộ Hải An 1 (khu vực Hoà Quý trước đây)": 170,
  "Chi bộ Hải An 2 (khu vực Hoà Quý trước đây)": 171,

  // STT 172-173: Công an và Quân sự
  "Đảng bộ (cơ sở) Công an phường": 172,
  "Chi bộ (cơ sở) Quân sự phường": 173,
};

async function updateOrganizationOrder() {
  try {
    console.log(
      "🚀 Starting to update organization order with exact names...\n"
    );

    // Get all organizations
    const snapshot = await db.collection("to_chuc_dang").get();

    if (snapshot.empty) {
      console.log("⚠️  No organizations found in database");
      return;
    }

    console.log(`📊 Found ${snapshot.size} organizations\n`);

    let updatedCount = 0;
    let notFoundCount = 0;
    const notFoundOrgs = [];

    // Batch update
    const batch = db.batch();

    snapshot.forEach((doc) => {
      const data = doc.data();
      const name = data.name;

      if (organizationOrder.hasOwnProperty(name)) {
        const stt = organizationOrder[name];
        batch.update(doc.ref, { stt });
        console.log(`✅ [${stt.toString().padStart(3, " ")}] ${name}`);
        updatedCount++;
      } else {
        // Set default STT for organizations not in the list
        batch.update(doc.ref, { stt: 999 });
        console.log(`⚠️  [999] ${name}`);
        notFoundCount++;
        notFoundOrgs.push(name);
      }
    });

    // Commit batch
    await batch.commit();

    console.log("\n" + "=".repeat(80));
    console.log("✨ Update completed successfully!");
    console.log("=".repeat(80));
    console.log(`✅ Updated with correct STT: ${updatedCount} organizations`);
    console.log(
      `⚠️  Not found in list (set to 999): ${notFoundCount} organizations`
    );

    if (notFoundOrgs.length > 0) {
      console.log("\n📝 Organizations not in the provided list:");
      notFoundOrgs.forEach((name, index) => {
        console.log(`   ${index + 1}. "${name}"`);
      });
    }

    console.log(
      "\n💡 Note: Organizations not in the list have been assigned STT = 999"
    );
    console.log("🔄 Please restart your Flutter app to see the changes");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error updating organization order:", error);
    process.exit(1);
  }
}

// Run the update
updateOrganizationOrder();
