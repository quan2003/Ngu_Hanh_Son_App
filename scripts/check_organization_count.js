/**
 * Check total organizations in database
 */
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function checkTotal() {
  try {
    const snapshot = await db.collection("to_chuc_dang").get();

    console.log("📊 ORGANIZATION COUNT CHECK");
    console.log("=".repeat(60));
    console.log(`Total organizations in database: ${snapshot.size}`);

    const sttCounts = {};
    const orgs = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      const stt = data.stt || "undefined";
      sttCounts[stt] = (sttCounts[stt] || 0) + 1;
      orgs.push({ stt, name: data.name });
    });

    console.log("\n📈 STT Distribution:");
    console.log("=".repeat(60));
    const sorted = Object.keys(sttCounts).sort((a, b) => {
      if (a === "undefined") return 1;
      if (b === "undefined") return -1;
      return Number(a) - Number(b);
    });

    sorted.forEach((stt) => {
      console.log(
        `  STT ${String(stt).padStart(3)}: ${sttCounts[stt]} organization(s)`
      );
    });

    // Check for duplicates
    console.log("\n🔍 Checking for duplicate STT...");
    const duplicates = sorted.filter(
      (stt) => sttCounts[stt] > 1 && stt !== "999"
    );

    if (duplicates.length > 0) {
      console.log("⚠️  Found duplicates:");
      duplicates.forEach((stt) => {
        console.log(`\n  STT ${stt} (${sttCounts[stt]} orgs):`);
        orgs
          .filter((o) => o.stt === Number(stt))
          .forEach((o) => {
            console.log(`    - ${o.name}`);
          });
      });
    } else {
      console.log("✅ No duplicate STT found (except 999)");
    }

    // Check for missing STT
    console.log("\n🔍 Checking for missing STT (1-173)...");
    const missing = [];
    for (let i = 1; i <= 173; i++) {
      if (!sorted.includes(String(i))) {
        missing.push(i);
      }
    }

    if (missing.length > 0) {
      console.log(`⚠️  Missing ${missing.length} STT values:`);
      console.log(`   ${missing.join(", ")}`);
    } else {
      console.log("✅ All STT from 1-173 are present");
    }

    console.log("\n" + "=".repeat(60));
    console.log("✨ Check complete!");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

checkTotal();
