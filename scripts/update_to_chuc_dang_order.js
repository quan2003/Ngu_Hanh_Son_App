/**
 * Script to update Tổ chức Đảng with STT (order number) field
 * This will add the 'stt' field to each organization in Firestore
 * based on the official order provided
 */

const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Mapping of organization names to their STT (order)
const organizationOrder = {
  "Đảng bộ các cơ quan Đảng": 1,
  "Đảng bộ Ủy ban nhân dân phường": 2,
  "Đảng bộ Trung tâm Y tế khu vực Ngũ Hành Sơn": 3,
  "Chi bộ Trường THPT Ngũ Hành Sơn": 4,
  "Chi bộ Trường THPT Võ Chí Công": 5,
  "Chi bộ Trường cấp I,II,III Hermann Gmeiner": 6,
  "Chi bộ Chi bộ Trường Cao đẳng du lịch Đà Nẵng": 7,
  "Chi bộ Làng trẻ em SOS": 8,
  "Chi bộ Công ty CP Xây lắp Thủy sản Việt Nam": 9,
  "Chi bộ Công ty Cổ phần Khu du lịch Bắc Mỹ An": 10,
  "Chi bộ Công ty TNHH Du lịch - Thương mại Phú An Thịnh": 11,
  "Chi bộ Công ty Cổ phần Thiên Long Châu": 12,
  "Chi bộ Trạm Y tế phường": 13,
  "Công ty TNHH TMDV Buổi sáng tuyệt vời": 14,
  "Công ty TNHH TM và Xây dựng 126": 15,
  "Công ty TNHH MTV Nhật Bích": 16,
  "THCS Lê Lợi": 17,
  "THCS Trần Đại Nghĩa": 18,
  "THCS Huỳnh Bá Chánh": 19,
  "THCS Nguyễn Bỉnh Khiêm": 20,
  "TH Lê Lai": 21,
  "TH Lê Bá Trinh": 22,
  "TH Trần Quang Diệu": 23,
  "TH Nguyễn Duy Trinh": 24,
  "TH Lê Văn Hiến": 25,
  "TH Mai Đăng Chơn": 26,
  "TH Phạm Hồng Thái": 27,
  "TH Tô Hiến Thành": 28,
  "MN Bạch Dương": 29,
  "MN Sen Hồng": 30,
  "MN Ngọc Lan": 31,
  "MN Ngôi Sao Nhỏ": 32,
  "MN Hoàng Lan": 33,
  "MN Tân Trà": 34,
  "MN Vàng Anh": 35,
  "MN Hoàng Anh": 36,
  "1 An Thượng": 37,
  "2 An Thượng": 38,
  "3 An Thượng": 39,
  "4 An Thượng": 40,
  "5 An Thượng": 41,
  "6 An Thượng": 42,
  "7 An Thượng": 43,
  "8 An Thượng": 44,
  "9 An Thượng": 45,
  "10-11 An Thượng": 46,
  "12 An Thượng": 47,
  "13 An Thượng": 48,
  "14 An Thượng": 49,
  "15-16-17 An Thượng": 50,
  "18 An Thượng": 51,
  "19 An Thượng": 52,
  "20-21 An Thượng": 53,
  "22 An Thượng": 54,
  "23 An Thượng": 55,
  "24-25 Mỹ Đa Đông": 56,
  "26-27 Mỹ Đa Đông": 57,
  "28 Mỹ Đa Đông": 58,
  "29 Mỹ Đa Đông": 59,
  "30 Mỹ Đa Đông": 60,
  "31 Mỹ Đa Đông": 61,
  "32 Mỹ Đa Đông": 62,
  "33 Mỹ Đa Đông": 63,
  "34-35 Mỹ Đa Đông": 64,
  "36 Mỹ Đa Đông": 65,
  "37 Mỹ Đa Đông": 66,
  "38 Mỹ Đa Đông": 67,
  "39 Mỹ Đa Đông": 68,
  "40 An Thượng": 69,
  "41-42 An Thượng": 70,
  "43-44-45 An Thượng": 71,
  "46 An Thượng": 72,
  "47-48 An Thượng": 73,
  "49-50-52 Mỹ Đa Tây": 74,
  "51 Mỹ Đa Tây": 75,
  "53 Mỹ Đa Tây": 76,
  "54 Mỹ Đa Tây": 77,
  "55 Mỹ Đa Tây": 78,
  "56-57 Mỹ Đa Tây": 79,
  "Mỹ Đa Đông 1": 80,
  "Mỹ Đa Đông 1A": 81,
  "Mỹ Đa Đông 2": 82,
  "Mỹ Đa Đông 3": 83,
  "Mỹ Đa Đông 3A": 84,
  "Mỹ Đa Đông 4": 85,
  "Mỹ Đa Đông 5": 86,
  "Mỹ Đa Tây 1": 87,
  "Mỹ Đa Tây 1A": 88,
  "Mỹ Đa Tây 2": 89,
  "Mỹ Đa Tây 3": 90,
  "Mỹ Đa Tây 4": 91,
  "Đa Mặn 1": 92,
  "Đa Mặn 2": 93,
  "Đa Mặn 2A": 94,
  "Đa Mặn 3": 95,
  "Đa Mặn 3A": 96,
  "Đa Mặn 3B": 97,
  "Đa Mặn 3C": 98,
  "Đa Mặn 4": 99,
  "Đa Mặn 4A": 100,
  "Đa Mặn 5": 101,
  "Đa Mặn 6": 102,
  "Đa Mặn 7": 103,
  "Đa Mặn 8": 104,
  "Đa Mặn 8A": 105,
  "Đa Mặn 9": 106,
  "Đa Mặn 9A": 107,
  "Đa Mặn 10": 108,
  "Đa Mặn 11": 109,
  "Đa Mặn 12": 110,
  "Chi bộ 1A": 111,
  "Chi bộ 1B": 112,
  "Chi bộ 2A": 113,
  "Chi bộ 2B": 114,
  "Chi bộ 2C": 115,
  "Chi bộ 3A": 116,
  "Chi bộ 3B": 117,
  "Chi bộ 4A": 118,
  "Chi bộ 4B": 119,
  "Chi bộ 5": 120,
  "Chi bộ 6": 121,
  "Chi bộ 7": 122,
  "Chi bộ 8A": 123,
  "Chi bộ 8B": 124,
  "Chi bộ 8C": 125,
  "Chi bộ 9A": 126,
  "Chi bộ 9B": 127,
  "Chi bộ 9C": 128,
  "Chi bộ 10A": 129,
  "Chi bộ 10B": 130,
  "Chi bộ 10C": 131,
  "Chi bộ 11": 132,
  "Chi bộ 12": 133,
  "Chi bộ 13A": 134,
  "Chi bộ 13B": 135,
  "Chi bộ 14": 136,
  "Chi bộ 15": 137,
  "Chi bộ 16A": 138,
  "Chi bộ 16B": 139,
  "Chi bộ 17A": 140,
  "Chi bộ 17B": 141,
  "Chi bộ 18A": 142,
  "Chi bộ 18B": 143,
  "Chi bộ 19A": 144,
  "Chi bộ 19B": 145,
  "Chi bộ 20A": 146,
  "Chi bộ 20B": 147,
  "Chi bộ 21A": 148,
  "Chi bộ 21B": 149,
  "Bình Kỳ": 150,
  "Bình Kỳ 1": 151,
  "Bình Kỳ 2A": 152,
  "Bình Kỳ 2B": 153,
  "Bá Tùng": 154,
  "Bá Tùng 1": 155,
  "Khái Tây 2A": 156,
  "Khái Tây 2B": 157,
  "Khuê Đông": 158,
  "Khuê Đông 1": 159,
  "Khuê Đông 2": 160,
  "Khuê Đông 3": 161,
  "Khuê Đông 4": 162,
  "Mân Quang 1": 163,
  "Mân quang 2": 164,
  "An Lưu": 165,
  "Thị An": 166,
  "Khái Tây": 167,
  "Khái Tây 1": 168,
  "Hải An": 169,
  "Hải An 1": 170,
  "Hải An 2": 171,
  "Đảng bộ Công an phường": 172,
  "Chi bộ Quân sự phường": 173,
};

async function updateOrganizationOrder() {
  try {
    console.log("🚀 Starting to update organization order...\n");

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
      let name = data.name;

      // Clean the name by removing extra text in parentheses
      // Examples:
      // "Chi bộ 1 An Thượng (khu vực Mỹ An trước đây)" -> "1 An Thượng"
      // "Đảng bộ (cơ sở) Các cơ quan Đảng" -> "Đảng bộ Các cơ quan Đảng" (keep this format)
      // "Chi bộ (cơ sở) Trường THPT Ngũ Hành Sơn" -> "Chi bộ Trường THPT Ngũ Hành Sơn"

      let cleanedName = name;

      // Remove "(khu vực ... trước đây)" text
      cleanedName = cleanedName.replace(/\s*\(khu vực[^)]*\)/g, "").trim();

      // Remove "(cơ sở)" text
      cleanedName = cleanedName.replace(/\s*\(cơ sở\)/g, "").trim();

      // Normalize spaces
      cleanedName = cleanedName.replace(/\s+/g, " ").trim();

      if (organizationOrder.hasOwnProperty(cleanedName)) {
        const stt = organizationOrder[cleanedName];
        batch.update(doc.ref, { stt });
        console.log(`✅ Updated: [${stt}] ${cleanedName}`);
        if (name !== cleanedName) {
          console.log(`   Original: ${name}`);
        }
        updatedCount++;
      } else {
        // Set default STT for organizations not in the list
        batch.update(doc.ref, { stt: 999 });
        console.log(`⚠️  Not in list (set to 999): ${cleanedName}`);
        if (name !== cleanedName) {
          console.log(`   Original: ${name}`);
        }
        notFoundCount++;
        notFoundOrgs.push({ original: name, cleaned: cleanedName });
      }
    });

    // Commit batch
    await batch.commit();

    console.log("\n" + "=".repeat(60));
    console.log("✨ Update completed successfully!");
    console.log("=".repeat(60));
    console.log(`✅ Updated: ${updatedCount} organizations`);
    console.log(`⚠️  Not found in list: ${notFoundCount} organizations`);
    if (notFoundOrgs.length > 0) {
      console.log("\n📝 Organizations not in the provided list:");
      notFoundOrgs.forEach((org, index) => {
        if (typeof org === "string") {
          console.log(`   ${index + 1}. ${org}`);
        } else {
          console.log(`   ${index + 1}. ${org.cleaned}`);
          console.log(`      Original: ${org.original}`);
        }
      });
    }

    console.log(
      "\n💡 Note: Organizations not in the list have been assigned STT = 999"
    );

    process.exit(0);
  } catch (error) {
    console.error("❌ Error updating organization order:", error);
    process.exit(1);
  }
}

// Run the update
updateOrganizationOrder();
