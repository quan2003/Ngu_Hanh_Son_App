/**
 * Add missing organization: MN Ngôi Sao Nhỏ (STT 32)
 */
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function addMissingOrg() {
  try {
    console.log("➕ Adding missing organization...\n");

    // Check if it already exists
    const existing = await db
      .collection("to_chuc_dang")
      .where("name", ">=", "Ngôi Sao Nhỏ")
      .where("name", "<=", "Ngôi Sao Nhỏ\uf8ff")
      .get();

    if (!existing.empty) {
      console.log("⚠️  Organization already exists");
      existing.forEach((doc) => {
        console.log(`   Name: ${doc.data().name}`);
        console.log(`   STT: ${doc.data().stt}`);
      });
      process.exit(0);
    }

    // Add new organization
    const newOrg = {
      name: "Chi bộ Trường Mầm non Ngôi Sao Nhỏ",
      type: "Chi bộ",
      stt: 32,
      officerInCharge: "",
      officerPosition: "",
      officerPhone: "",
      secretary: "",
      secretaryPhone: "",
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const docRef = await db.collection("to_chuc_dang").add(newOrg);

    console.log("✅ Successfully added:");
    console.log(`   ID: ${docRef.id}`);
    console.log(`   Name: ${newOrg.name}`);
    console.log(`   STT: ${newOrg.stt}`);
    console.log(`   Type: ${newOrg.type}`);

    console.log("\n💡 You can now update the details in the admin panel");
    console.log("🔄 Please restart your Flutter app to see the changes");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

addMissingOrg();
