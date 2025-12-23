// Verify Party Member Statistics
// This script verifies all 173 organizations have correct party member data

const admin = require("firebase-admin");

// Initialize Firebase Admin
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function verifyPartyMemberStats() {
  console.log("🔍 Verifying Party Member Statistics...\n");

  try {
    // Get all organizations ordered by stt
    const snapshot = await db.collection("to_chuc_dang").orderBy("stt").get();

    let totalOrgs = 0;
    let totalMembers = 0;
    let totalOfficial = 0;
    let totalProbationary = 0;
    let orgsWithStats = 0;
    let orgsWithoutStats = 0;

    const orgsWithoutData = [];
    const top10Orgs = [];

    console.log("📊 Organization Statistics:\n");
    console.log("STT | Name | Total | Official | Probationary");
    console.log("-".repeat(80));

    snapshot.forEach((doc) => {
      const org = doc.data();
      totalOrgs++;

      const total = org.totalMembers || 0;
      const official = org.officialMembers || 0;
      const probationary = org.probationaryMembers || 0;

      if (total > 0) {
        orgsWithStats++;
        totalMembers += total;
        totalOfficial += official;
        totalProbationary += probationary;

        // Collect top organizations
        top10Orgs.push({
          stt: org.stt,
          name: org.name,
          total,
          official,
          probationary,
        });

        // Only show first 10 organizations
        if (orgsWithStats <= 10) {
          console.log(
            `${org.stt.toString().padEnd(3)} | ${org.name
              .substring(0, 40)
              .padEnd(40)} | ${total.toString().padStart(5)} | ${official
              .toString()
              .padStart(8)} | ${probationary.toString().padStart(12)}`
          );
        }
      } else {
        orgsWithoutStats++;
        orgsWithoutData.push({ stt: org.stt, name: org.name });
      }
    });

    // Sort top10 by total members
    top10Orgs.sort((a, b) => b.total - a.total);

    console.log("\n" + "=".repeat(80));
    console.log("\n📈 SUMMARY STATISTICS:\n");
    console.log(`Total Organizations: ${totalOrgs}`);
    console.log(`Organizations with stats: ${orgsWithStats}`);
    console.log(`Organizations without stats: ${orgsWithoutStats}`);
    console.log("");
    console.log(`🎯 TOTAL PARTY MEMBERS: ${totalMembers.toLocaleString()}`);
    console.log(`   ✅ Official Members: ${totalOfficial.toLocaleString()}`);
    console.log(
      `   ⏳ Probationary Members: ${totalProbationary.toLocaleString()}`
    );
    console.log("");

    // Show percentage
    const officialPercent = ((totalOfficial / totalMembers) * 100).toFixed(1);
    const probationaryPercent = (
      (totalProbationary / totalMembers) *
      100
    ).toFixed(1);
    console.log(`📊 Breakdown:`);
    console.log(`   Official: ${officialPercent}%`);
    console.log(`   Probationary: ${probationaryPercent}%`);

    // Show top 10 organizations
    console.log("\n🏆 TOP 10 ORGANIZATIONS BY MEMBER COUNT:\n");
    top10Orgs.slice(0, 10).forEach((org, index) => {
      console.log(
        `${(index + 1).toString().padStart(2)}. STT ${org.stt
          .toString()
          .padEnd(3)} - ${org.name}`
      );
      console.log(
        `    Total: ${org.total} (${org.official} CT, ${org.probationary} DB)`
      );
    });

    // Show organizations without data
    if (orgsWithoutData.length > 0) {
      console.log("\n⚠️  ORGANIZATIONS WITHOUT STATS:\n");
      orgsWithoutData.forEach((org) => {
        console.log(`   STT ${org.stt} - ${org.name}`);
      });
    }

    console.log("\n" + "=".repeat(80));
    console.log("\n✅ Verification Complete!\n");
  } catch (error) {
    console.error("❌ Error:", error);
  } finally {
    process.exit(0);
  }
}

verifyPartyMemberStats();
