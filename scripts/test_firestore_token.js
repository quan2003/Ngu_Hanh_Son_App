/**
 * Test fetching FCM token from Firestore directly
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

async function testGetToken(userId) {
  try {
    console.log(`🔍 Fetching FCM token for user: ${userId}`);
    console.log("");

    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.error(`❌ User not found: ${userId}`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    console.log("📄 User data:");
    console.log(`  Email: ${userData.email}`);
    console.log(`  Name: ${userData.name || "N/A"}`);
    console.log(`  Role: ${userData.role || "N/A"}`);
    console.log("");

    if (fcmToken) {
      console.log("✅ FCM Token found:");
      console.log(`  ${fcmToken.substring(0, 50)}...`);
      console.log("");
      console.log(`  Full token: ${fcmToken}`);
      console.log("");
      console.log(
        `  Token updated: ${userData.fcmTokenUpdatedAt || "Unknown"}`
      );
    } else {
      console.error("❌ No FCM token in user document");
      console.log("Available fields:", Object.keys(userData));
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

const userId = process.argv[2] || "lEIFKpXp0eOAlT3Owf5xI48M3ib2";

testGetToken(userId);
