/**
 * Script to fix the remaining 3 organizations
 */

const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function fixRemaining() {
  try {
    console.log("🔧 Fixing remaining 3 organizations...\n");

    const snapshot = await db.collection("to_chuc_dang").get();
    const batch = db.batch();
    let count = 0;

    snapshot.forEach((doc) => {
      const name = doc.data().name;

      // Fix Chi bộ 34-35 Mỹ Đa Đông
      if (name.includes("34-35 Mỹ Đa Đông")) {
        batch.update(doc.ref, { stt: 64 });
        console.log(`✅ [64] ${name}`);
        count++;
      }

      // Fix Chi bộ 20B (with typo "đày")
      if (name.includes("20B") && name.includes("đày")) {
        batch.update(doc.ref, { stt: 147 });
        console.log(`✅ [147] ${name} (fixed typo)`);
        count++;
      }

      // Nam Việt Á company - not in original list, keep at 999
      if (name.includes("Nam Việt Á")) {
        console.log(`⚠️  [999] ${name} (not in original list)`);
      }
    });

    await batch.commit();

    console.log(`\n✨ Fixed ${count} organizations`);
    console.log("🔄 Please restart your Flutter app to see all changes");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

fixRemaining();
