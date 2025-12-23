const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkHouseholdStats() {
  console.log("🔍 Checking Household Stats vs Tổ Dân Phố...\n");

  // Get all Tổ Dân Phố
  const toDanPhoSnapshot = await db.collection("to_dan_pho").get();
  console.log(`📊 Total Tổ Dân Phố: ${toDanPhoSnapshot.size}`);

  const toDanPhoIds = new Set();
  toDanPhoSnapshot.forEach((doc) => {
    toDanPhoIds.add(doc.id);
  });

  // Get all Household Stats
  const statsSnapshot = await db.collection("household_stats").get();
  console.log(`📊 Total Household Stats: ${statsSnapshot.size}\n`);

  const statsTdpIds = new Set();
  statsSnapshot.forEach((doc) => {
    statsTdpIds.add(doc.id); // doc.id IS the tdpId
  });

  // Check matches
  console.log("✅ Tổ Dân Phố có stats:");
  let matchCount = 0;
  toDanPhoSnapshot.forEach((doc) => {
    if (statsTdpIds.has(doc.id)) {
      matchCount++;
      const statsDoc = statsSnapshot.docs.find((s) => s.id === doc.id);
      const statsData = statsDoc.data();
      console.log(`  ✓ ${doc.data().name} (${doc.id})`);
      console.log(
        `    → ${statsData.reportedHouseholdCount} hộ, ${statsData.populationCount} nhân khẩu`
      );
    }
  });

  console.log(
    `\n❌ Tổ Dân Phố KHÔNG có stats: (${toDanPhoSnapshot.size - matchCount} tổ)`
  );
  toDanPhoSnapshot.forEach((doc) => {
    if (!statsTdpIds.has(doc.id)) {
      console.log(`  ✗ ${doc.data().name} (ID: ${doc.id})`);
    }
  });

  console.log(`\n📊 Summary:`);
  console.log(`  - Tổng Tổ Dân Phố: ${toDanPhoSnapshot.size}`);
  console.log(`  - Có stats: ${matchCount}`);
  console.log(`  - Chưa có stats: ${toDanPhoSnapshot.size - matchCount}`);
}

checkHouseholdStats()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Error:", err);
    process.exit(1);
  });
