// Check FCM tokens in Firestore
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkFCMTokens() {
  console.log("🔍 Checking FCM tokens in users collection...\n");

  try {
    const usersSnapshot = await db.collection("users").get();

    console.log(`📊 Total users: ${usersSnapshot.size}\n`);

    let usersWithToken = 0;
    let usersWithoutToken = 0;

    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      const hasFCMToken = !!data.fcmToken;

      if (hasFCMToken) {
        usersWithToken++;
        console.log(`✅ User: ${doc.id}`);
        console.log(`   Email: ${data.email || "N/A"}`);
        console.log(`   Role: ${data.role || "user"}`);
        console.log(`   FCM Token: ${data.fcmToken.substring(0, 50)}...`);
        console.log(
          `   Token Updated: ${data.fcmTokenUpdatedAt?.toDate() || "N/A"}`
        );
        console.log("");
      } else {
        usersWithoutToken++;
        console.log(`❌ User: ${doc.id}`);
        console.log(`   Email: ${data.email || "N/A"}`);
        console.log(`   Role: ${data.role || "user"}`);
        console.log(`   ⚠️  NO FCM TOKEN`);
        console.log("");
      }
    });

    console.log("\n📈 Summary:");
    console.log(`✅ Users with FCM token: ${usersWithToken}`);
    console.log(`❌ Users without FCM token: ${usersWithoutToken}`);
  } catch (error) {
    console.error("❌ Error:", error);
  }

  process.exit(0);
}

checkFCMTokens();
