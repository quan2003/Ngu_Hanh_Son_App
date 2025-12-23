const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkPartyMemberTotals() {
  console.log("📊 CHECKING PARTY MEMBER TOTALS");
  console.log("=".repeat(60));

  try {
    const snapshot = await db.collection("to_chuc_dang").get();

    let totalMembers = 0;
    let officialMembers = 0;
    let probationaryMembers = 0;
    let orgCount = 0;
    let orgsWithData = 0;

    const details = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      orgCount++;

      const orgTotal = data.totalMembers || 0;
      const orgOfficial = data.officialMembers || 0;
      const orgProb = data.probationaryMembers || 0;

      if (orgTotal > 0) {
        orgsWithData++;
        details.push({
          stt: data.stt || 999,
          name: data.name,
          total: orgTotal,
          official: orgOfficial,
          probationary: orgProb,
        });
      }

      totalMembers += orgTotal;
      officialMembers += orgOfficial;
      probationaryMembers += orgProb;
    });

    console.log(`\n📈 TOTAL STATISTICS:`);
    console.log(`   Total Organizations: ${orgCount}`);
    console.log(`   Organizations with members: ${orgsWithData}`);
    console.log(`\n👥 PARTY MEMBERS:`);
    console.log(`   Total Members: ${totalMembers}`);
    console.log(`   Official Members (Chính thức): ${officialMembers}`);
    console.log(`   Probationary Members (Dự bị): ${probationaryMembers}`);
    console.log(
      `   Sum Check: ${officialMembers} + ${probationaryMembers} = ${
        officialMembers + probationaryMembers
      } ${officialMembers + probationaryMembers === totalMembers ? "✅" : "❌"}`
    );

    console.log(`\n📋 TOP 10 ORGANIZATIONS BY MEMBER COUNT:`);
    details.sort((a, b) => b.total - a.total);
    details.slice(0, 10).forEach((org, idx) => {
      console.log(`   ${idx + 1}. [STT ${org.stt}] ${org.name}`);
      console.log(
        `      Total: ${org.total} (Official: ${org.official}, Probationary: ${org.probationary})`
      );
    });

    console.log(`\n🎯 EXPECTED vs ACTUAL:`);
    console.log(`   Expected Total: 4905`);
    console.log(`   Actual Total: ${totalMembers}`);
    console.log(`   Difference: ${4905 - totalMembers}`);
    console.log(`\n   Expected Official: 4597`);
    console.log(`   Actual Official: ${officialMembers}`);
    console.log(`   Difference: ${4597 - officialMembers}`);
    console.log(`\n   Expected Probationary: 308`);
    console.log(`   Actual Probationary: ${probationaryMembers}`);
    console.log(`   Difference: ${308 - probationaryMembers}`);
  } catch (error) {
    console.error("❌ Error:", error);
  }

  console.log("\n" + "=".repeat(60));
  console.log("✨ Check complete!");
  process.exit(0);
}

checkPartyMemberTotals();
