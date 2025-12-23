/**
 * Fix missing STT 32 and 147
 */
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function fixMissingSTT() {
  try {
    console.log("🔧 Fixing missing STT...\n");

    const snapshot = await db.collection("to_chuc_dang").get();
    const batch = db.batch();
    let fixed = 0;

    // Find organizations with STT 999
    const stt999Orgs = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      if (data.stt === 999) {
        stt999Orgs.push({
          id: doc.id,
          name: data.name,
          ref: doc.ref,
        });
      }

      // Fix Chi bộ 20B (might have typo "đày" instead of "đây")
      if (data.name && data.name.includes("20B")) {
        console.log(`Found Chi bộ 20B: "${data.name}"`);
        console.log(`Current STT: ${data.stt}`);
        if (data.stt === 999 || data.stt === 147) {
          batch.update(doc.ref, { stt: 147 });
          console.log(`✅ Setting STT to 147\n`);
          fixed++;
        }
      }
    });

    console.log(`\nOrganizations with STT = 999:`);
    stt999Orgs.forEach((org, i) => {
      console.log(`${i + 1}. ${org.name}`);
    });

    // Check if we need to add STT 32 (MN Ngôi Sao Nhỏ)
    const has32 = await db
      .collection("to_chuc_dang")
      .where("name", ">=", "Ngôi Sao Nhỏ")
      .where("name", "<=", "Ngôi Sao Nhỏ\uf8ff")
      .get();

    if (has32.empty) {
      console.log(
        '\n⚠️  Note: "MN Ngôi Sao Nhỏ" (STT 32) not found in database'
      );
      console.log("   This organization may need to be added manually");
    }

    if (fixed > 0) {
      await batch.commit();
      console.log(`\n✨ Fixed ${fixed} organization(s)`);
    } else {
      console.log("\n💡 No changes needed");
    }

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

fixMissingSTT();
