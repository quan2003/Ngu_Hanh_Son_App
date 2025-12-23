#!/usr/bin/env node

/**
 * Script to upload Excel data to Firebase Firestore
 *
 * Usage: node upload_excel_to_firebase.js <excel_file_path>
 *
 * The Excel file should have these sheets:
 * - Sheet1: ToChuDang_NHS (Đảng bộ data)
 * - Sheet2: ToChuDang_NHS (Chi bộ data)
 */

const admin = require("firebase-admin");
const XLSX = require("xlsx");
const path = require("path");
const fs = require("fs");

// Initialize Firebase Admin
const serviceAccountPath = path.join(
  __dirname,
  "..",
  "firebase-admin-key.json"
);

if (!fs.existsSync(serviceAccountPath)) {
  console.error("❌ firebase-admin-key.json not found!");
  console.error(
    "   Please download the service account key from Firebase Console"
  );
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Constants
const COLLECTIONS = {
  TO_CHUC_DANG: "to_chuc_dang",
  TO_DAN_PHO: "to_dan_pho",
  CONFIG: "config",
};

/**
 * Parse Excel data from ToChucDang_NHS and ToDanPho_NHS sheets
 *
 * ToChucDang_NHS columns:
 * - ID, LoaiToChuc, TenToChuc, UyVienPhuTrach, ChucVuUyVien, DienThoaiUyVien, BiThu, DienThoaiBiThu
 *
 * ToDanPho_NHS columns:
 * - ID, ToDanPho, CanBoPhuTrach, ChucVuCanBo, DienThoaiCanBo, ToTruong, DienThoaiToTruong
 */
function parseExcelData(filePath) {
  try {
    const workbook = XLSX.readFile(filePath);
    console.log("📊 Excel sheets found:", workbook.SheetNames);

    let toChucDangData = [];
    let toDanPhoData = [];

    // Parse all sheets
    for (const sheetName of workbook.SheetNames) {
      const worksheet = workbook.Sheets[sheetName];
      const data = XLSX.utils.sheet_to_json(worksheet);

      console.log(`\n📄 Sheet: ${sheetName}`);
      console.log(`   Rows: ${data.length}`);

      if (data.length > 0) {
        const columns = Object.keys(data[0]);
        console.log(`   Columns: ${columns.join(", ")}`);

        // Match sheet by name
        if (sheetName.includes("ToChucDang")) {
          toChucDangData = data;
          console.log(`   ✅ Matched as ToChucDang data`);
        } else if (sheetName.includes("ToDanPho")) {
          toDanPhoData = data;
          console.log(`   ✅ Matched as ToDanPho data`);
        }
      }
    }

    console.log(`\n✅ Parsed ${toChucDangData.length} ToChucDang records`);
    console.log(`✅ Parsed ${toDanPhoData.length} ToDanPho records`);

    return { toChucDangData, toDanPhoData };
  } catch (error) {
    console.error("❌ Error reading Excel file:", error.message);
    process.exit(1);
  }
}

/**
 * Transform Excel row to ToChucDang document
 * LoaiToChuc: Chi bộ / Đảng bộ cơ sở
 */
function transformToChucDang(row, index) {
  // Ensure we have a valid name
  const name = row.TenToChuc || row.LoaiToChuc || `ToChucDang_${index + 1}`;
  if (!name || name.trim() === "") return null;

  return {
    id: `to_chuc_dang_${String(row.ID || index + 1).padStart(3, "0")}`,
    type: row.LoaiToChuc || "Chi bộ",
    name: name.trim(),
    officerInCharge: (row.UyVienPhuTrach || "").trim() || "",
    officerPosition: (row.ChucVuUyVien || "").trim() || "",
    officerPhone: (row.DienThoaiUyVien || "").trim() || "",
    secretary: (row.BiThu || "").trim() || "",
    secretaryPhone: (row.DienThoaiBiThu || "").trim() || "",
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

/**
 * Transform Excel row to ToDanPho document
 */
function transformToDanPho(row, index) {
  // Ensure we have a valid name
  const name = row.ToDanPho || `ToDanPho_${index + 1}`;
  if (!name || name.trim() === "") return null;

  return {
    id: `to_dan_pho_${String(row.ID || index + 1).padStart(3, "0")}`,
    name: name.trim(),
    staffInCharge: (row.CanBoPhuTrach || "").trim() || "",
    staffPosition: (row.ChucVuCanBo || "").trim() || "",
    staffPhone: (row.DienThoaiCanBo || "").trim() || "",
    leader: (row.ToTruong || "").trim() || "",
    leaderPhone: (row.DienThoaiToTruong || "").trim() || "",
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

/**
 * Upload data to Firestore collection
 */
async function uploadDataToFirestore(
  collectionName,
  dataList,
  batchSize = 100
) {
  console.log(
    `\n📤 Uploading ${dataList.length} records to collection: ${collectionName}`
  );

  let batch = db.batch();
  let count = 0;
  const failedRecords = [];

  for (const data of dataList) {
    if (!data) {
      failedRecords.push(null);
      continue;
    }

    if (!data.id || !data.name) {
      failedRecords.push(data);
      continue;
    }

    const docRef = db.collection(collectionName).doc(data.id);
    batch.set(docRef, data, { merge: true });
    count++;

    if (count % batchSize === 0) {
      await batch.commit();
      console.log(`   ✅ Uploaded ${count} records`);
      batch = db.batch();
    }
  }

  if (count % batchSize !== 0) {
    await batch.commit();
  }

  console.log(`   ✅ Total uploaded: ${count} records`);

  if (failedRecords.length > 0) {
    console.warn(
      `   ⚠️  Skipped ${failedRecords.length} invalid records (empty name or ID)`
    );
  }

  return count;
}

/**
 * Initialize admin config to allow adding admins later
 */
async function initializeAdminConfig() {
  console.log(`\n🔐 Initializing admin config...`);

  const adminConfig = {
    emails: ["admin@nhs.vn", "admin@gmail.com", "quanly@nhs.vn"],
    updatedAt: new Date(),
  };

  await db
    .collection(COLLECTIONS.CONFIG)
    .doc("admin_emails")
    .set(adminConfig, { merge: true });
  console.log("   ✅ Admin config initialized");
}

/**
 * Main function
 */
async function main() {
  try {
    const args = process.argv.slice(2);

    if (args.length === 0) {
      console.log("❌ Please provide the Excel file path");
      console.log("Usage: node upload_excel_to_firebase.js <excel_file_path>");
      process.exit(1);
    }

    const excelFilePath = args[0];

    if (!fs.existsSync(excelFilePath)) {
      console.error(`❌ File not found: ${excelFilePath}`);
      process.exit(1);
    }

    console.log("🚀 Starting Excel to Firebase upload...");
    console.log(`📁 File: ${excelFilePath}\n`);

    // Parse Excel
    const { toChucDangData, toDanPhoData } = parseExcelData(excelFilePath);

    // Validate data
    if (toChucDangData.length === 0 && toDanPhoData.length === 0) {
      console.warn("⚠️  No data found in Excel");
      process.exit(0);
    } // Transform data
    let uploadedToChucDang = 0;
    let uploadedToDanPho = 0;

    if (toChucDangData.length > 0) {
      const toChucDangList = toChucDangData
        .map((row, index) => transformToChucDang(row, index))
        .filter((item) => item !== null);
      uploadedToChucDang = await uploadDataToFirestore(
        COLLECTIONS.TO_CHUC_DANG,
        toChucDangList
      );
    }

    if (toDanPhoData.length > 0) {
      const toDanPhoList = toDanPhoData
        .map((row, index) => transformToDanPho(row, index))
        .filter((item) => item !== null);
      uploadedToDanPho = await uploadDataToFirestore(
        COLLECTIONS.TO_DAN_PHO,
        toDanPhoList
      );
    }

    // Initialize admin config
    await initializeAdminConfig();

    console.log("\n" + "=".repeat(70));
    console.log("✅ Upload completed successfully!");
    console.log("=".repeat(70));
    console.log(`   📊 Tổ chức Đảng: ${uploadedToChucDang} records`);
    console.log(`   📊 Tổ dân phố: ${uploadedToDanPho} records`);
    console.log(`   🔐 Admin config: Initialized`);
    console.log("=".repeat(70) + "\n");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error.message);
    console.error(error);
    process.exit(1);
  }
}

main();
