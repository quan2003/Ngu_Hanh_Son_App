/**
 * Send FCM notification directly using Node.js and Firebase Admin SDK
 * This bypasses Supabase Edge Function for testing
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

async function sendDirectFCM(userId, title, body) {
  try {
    console.log("📤 Sending FCM notification directly...");
    console.log(`User: ${userId}`);
    console.log(`Title: ${title}`);
    console.log(`Body: ${body}`);
    console.log("");

    // Get FCM token
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.error(`❌ User not found: ${userId}`);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      console.error(`❌ User has no FCM token`);
      return;
    }

    console.log(`✅ FCM Token: ${fcmToken.substring(0, 30)}...`);
    console.log("");

    // Send FCM using Admin SDK
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "info",
        user_id: userId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nhs_dangbo_high_importance",
          priority: "high",
          sound: "default",
          visibility: "public",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);

    console.log("✅ FCM sent successfully!");
    console.log(`   Message ID: ${response}`);
    console.log("");
    console.log("📱 CHECK YOUR PHONE NOW! (even if app is closed)");
  } catch (error) {
    console.error("❌ Error:", error.message);
    if (error.code) {
      console.error(`   Error code: ${error.code}`);
    }
  }
}

const userId = process.argv[2];
const title = process.argv[3] || "Test Direct FCM";
const body = process.argv[4] || "Notification khi app đã tắt hẳn";

if (!userId) {
  console.log("Usage:");
  console.log("  node send_fcm_direct.js <userId> [title] [body]");
  console.log("");
  console.log("Example:");
  console.log(
    '  node send_fcm_direct.js lEIFKpXp0eOAlT3Owf5xI48M3ib2 "Test" "App killed"'
  );
  process.exit(1);
}

sendDirectFCM(userId, title, body);
