// Get FCM token for a specific user
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function getUserFCMToken(userId) {
  console.log(`🔍 Getting FCM token for user: ${userId}\n`);

  try {
    // Check in users collection
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.log("❌ User not found");
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (fcmToken) {
      console.log("✅ FCM Token found:\n");
      console.log(`Token: ${fcmToken}`);
      console.log(`Email: ${userData.email || "N/A"}`);
      console.log(`Role: ${userData.role || "user"}`);
      console.log(
        `Last Updated: ${userData.fcmTokenUpdatedAt?.toDate() || "N/A"}`
      );
      console.log("\n💡 Use this command to send test notification:");
      console.log(
        `node send_notification_with_fcm.js ${userId} "${fcmToken}" "Test Title" "Test Message"`
      );
      return fcmToken;
    } else {
      console.log("⚠️  No FCM token found for this user");
      console.log(
        "💡 Make sure the user has logged in and granted notification permission"
      );
      return null;
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
    return null;
  }
}

// CLI
const args = process.argv.slice(2);

if (args.length === 0) {
  console.log("❌ Usage: node get_fcm_token.js <userId>");
  console.log("\nExample:");
  console.log("  node get_fcm_token.js Aa07GEX3GbVS8Dc6kOuGaY4Z5x22");
  process.exit(1);
}

const userId = args[0];
getUserFCMToken(userId).then(() => process.exit(0));
