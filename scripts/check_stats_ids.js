const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkStatsIds() {
  console.log("🔍 Checking Household Stats Document IDs...\n");

  const statsSnapshot = await db.collection("household_stats").limit(10).get();

  console.log(`First 10 household_stats documents:\n`);
  statsSnapshot.forEach((doc) => {
    const data = doc.data();
    console.log(`📄 Doc ID: "${doc.id}"`);
    console.log(`   tdpId in data: "${data.tdpId || "MISSING"}"`);
    console.log(`   tdpName: "${data.tdpName || "MISSING"}"\n`);
  });
}

checkStatsIds()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Error:", err);
    process.exit(1);
  });
