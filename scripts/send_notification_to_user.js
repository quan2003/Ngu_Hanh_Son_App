/**
 * Send notification to user via FCM + create in Supabase
 * This works even when app is closed!
 *
 * Usage:
 *   node send_notification_to_user.js <userId> <title> <message> [type]
 *
 * Example:
 *   node send_notification_to_user.js Aa07GEX3GbVS8Dc6kOuGaY4Z5x22 "Test" "Hello!" info
 */

const admin = require("firebase-admin");
const { createClient } = require("@supabase/supabase-js");
const path = require("path");

// Initialize Firebase Admin
const serviceAccount = require(path.join(
  __dirname,
  "..",
  "firebase-admin-key.json"
));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

// Initialize Supabase
// TODO: Update these with your actual Supabase credentials
const SUPABASE_URL =
  process.env.SUPABASE_URL || "https://your-project.supabase.co";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "your-anon-key";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/**
 * Send notification to a specific user
 */
async function sendNotificationToUser(userId, title, message, type = "info") {
  try {
    console.log("📤 Sending notification to user:", userId);
    console.log("  Title:", title);
    console.log("  Message:", message);
    console.log("  Type:", type);
    console.log("");

    // Step 1: Get FCM token from Firestore
    console.log("1️⃣ Getting FCM token from Firestore...");
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      throw new Error("❌ User not found in Firestore");
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new Error(
        "❌ User does not have FCM token. User needs to login to the app first."
      );
    }

    console.log("✅ Found FCM token:", fcmToken.substring(0, 20) + "...");
    console.log(""); // Step 2: Send via FCM
    console.log("2️⃣ Sending via Firebase Cloud Messaging...");

    // IMPORTANT: For notifications to show when app is killed/background,
    // we MUST send a notification-only message (no data field).
    // FCM automatically displays notification-only messages even when app is terminated.
    const fcmResponse = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: title,
        body: message,
      },
      // NOTE: We include data for click action when user taps notification
      // But we keep it minimal to ensure notification displays
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: type,
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
              body: message,
            },
            sound: "default",
            badge: 1,
            category: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
      },
    });

    console.log("✅ FCM notification sent!");
    console.log("  Message ID:", fcmResponse);
    console.log("");

    // Step 3: Create in Supabase (backup + for app display)
    console.log("3️⃣ Creating notification in Supabase...");

    if (SUPABASE_URL === "https://your-project.supabase.co") {
      console.log(
        "⚠️  Supabase URL not configured - skipping Supabase creation"
      );
      console.log("💡 Update SUPABASE_URL and SUPABASE_ANON_KEY in the script");
      console.log("");
    } else {
      const { data, error } = await supabase
        .from("notifications")
        .insert({
          user_id: userId,
          title: title,
          message: message,
          type: type,
          read: false,
          created_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (error) {
        console.log("⚠️  Error creating in Supabase:", error.message);
        console.log("💡 This is OK - FCM was sent successfully");
      } else {
        console.log("✅ Notification created in Supabase!");
        console.log("  ID:", data.id);
      }
      console.log("");
    }

    console.log("🎉 SUCCESS! Notification sent to user:", userId);
    console.log("");
    console.log("📱 What happens now:");
    console.log("  • If app is open: Notification appears immediately");
    console.log("  • If app is closed: Notification popup appears");
    console.log("  • User taps notification → App opens → Shows notification");
    console.log("");

    return {
      fcmMessageId: fcmResponse,
      success: true,
    };
  } catch (error) {
    console.error("");
    console.error("❌ ERROR:", error.message);
    console.error("");

    if (error.message.includes("FCM token")) {
      console.error("💡 Solution: User needs to:");
      console.error("  1. Open the app");
      console.error("  2. Login");
      console.error("  3. Grant notification permission");
      console.error("  4. Wait for FCM token to be saved");
    }

    throw error;
  }
}

/**
 * Send notification to multiple users
 */
async function sendNotificationToMultipleUsers(
  userIds,
  title,
  message,
  type = "info"
) {
  console.log(`📤 Sending notification to ${userIds.length} users...`);
  console.log("");

  const results = [];

  for (const userId of userIds) {
    try {
      const result = await sendNotificationToUser(userId, title, message, type);
      results.push({ userId, success: true, ...result });
    } catch (error) {
      results.push({ userId, success: false, error: error.message });
      console.error(`❌ Failed for user ${userId}:`, error.message);
      console.log("");
    }
  }

  // Summary
  const successful = results.filter((r) => r.success).length;
  const failed = results.filter((r) => !r.success).length;

  console.log("📊 Summary:");
  console.log(`  ✅ Successful: ${successful}`);
  console.log(`  ❌ Failed: ${failed}`);
  console.log("");

  return results;
}

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 3) {
    console.log(
      "❌ Usage: node send_notification_to_user.js <userId> <title> <message> [type]"
    );
    console.log("");
    console.log("Example:");
    console.log(
      '  node send_notification_to_user.js Aa07GEX3GbVS8Dc6kOuGaY4Z5x22 "Test Notification" "Hello from FCM!" info'
    );
    console.log("");
    console.log("Types: info, warning, error, success");
    console.log("");
    console.log("For multiple users (comma-separated):");
    console.log(
      '  node send_notification_to_user.js user1,user2,user3 "Title" "Message"'
    );
    process.exit(1);
  }

  const [userIdOrList, title, message, type] = args;

  // Check if multiple users
  if (userIdOrList.includes(",")) {
    const userIds = userIdOrList.split(",").map((id) => id.trim());
    sendNotificationToMultipleUsers(userIds, title, message, type || "info")
      .then(() => {
        console.log("✅ Done!");
        process.exit(0);
      })
      .catch((error) => {
        console.error("❌ Failed:", error.message);
        process.exit(1);
      });
  } else {
    sendNotificationToUser(userIdOrList, title, message, type || "info")
      .then(() => {
        console.log("✅ Done!");
        console.log("💡 Check the device - notification should appear!");
        process.exit(0);
      })
      .catch((error) => {
        console.error("❌ Failed:", error.message);
        process.exit(1);
      });
  }
}

module.exports = {
  sendNotificationToUser,
  sendNotificationToMultipleUsers,
};
