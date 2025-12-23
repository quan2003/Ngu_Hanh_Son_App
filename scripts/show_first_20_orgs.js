/**
 * Display first 20 organizations in correct order
 */
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function showFirst20() {
  try {
    console.log("📋 FIRST 20 ORGANIZATIONS IN ORDER");
    console.log("=".repeat(80));

    const snapshot = await db
      .collection("to_chuc_dang")
      .orderBy("stt")
      .limit(20)
      .get();

    if (snapshot.empty) {
      console.log("⚠️  No data found");
      process.exit(0);
    }

    console.log(`Total fetched: ${snapshot.size}\n`);

    snapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(
        `${(index + 1).toString().padStart(2)}. [STT ${data.stt
          .toString()
          .padStart(3)}] ${data.name}`
      );
    });

    console.log("\n" + "=".repeat(80));
    console.log(
      "✨ If this order is correct in the script but not in the app,"
    );
    console.log(
      "   you need to FULLY RESTART the Flutter app (not just hot reload)"
    );
    console.log("\n💡 Try these steps:");
    console.log("   1. Stop the app completely");
    console.log("   2. Run: flutter clean");
    console.log("   3. Run: flutter run");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

showFirst20();
