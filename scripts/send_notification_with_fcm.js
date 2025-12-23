/**
 * Send notification via Firebase Cloud Messaging (FCM)
 * This will work even when app is in background or terminated
 *
 * The notification will be:
 * 1. Sent via FCM to the device
 * 2. Created in Supabase by the app when received
 * 3. Shown as local notification
 *
 * Usage:
 * node send_notification_with_fcm.js <userId> <fcmToken> <title> <message>
 *
 * Example:
 * node send_notification_with_fcm.js Aa07GEX3GbVS8Dc6kOuGaY4Z5x22 "cXXXXXXXXX" "Test" "Hello"
 */

const admin = require("firebase-admin");
const path = require("path");

// Initialize Firebase Admin
const serviceAccount = require(path.join(
  __dirname,
  "..",
  "firebase-admin-key.json"
));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

/**
 * Send notification to specific device
 */
async function sendNotificationToDevice(
  userId,
  fcmToken,
  title,
  message,
  type = "info"
) {
  try {
    console.log("📤 Sending notification...");
    console.log("  User ID:", userId);
    console.log("  FCM Token:", fcmToken.substring(0, 20) + "...");
    console.log("  Title:", title);
    console.log("  Message:", message);

    const payload = {
      token: fcmToken,
      notification: {
        title: title,
        body: message,
      },
      data: {
        userId: userId,
        user_id: userId,
        title: title,
        body: message,
        message: message,
        type: type,
        timestamp: new Date().toISOString(),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nhs_dangbo_high_importance",
          priority: "high",
          sound: "default",
          visibility: "public",
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
          },
        },
      },
    };

    const response = await admin.messaging().send(payload);
    console.log("✅ Notification sent successfully!");
    console.log("  Message ID:", response);
    return response;
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    throw error;
  }
}

/**
 * Send notification to all users (via topics)
 */
async function sendNotificationToTopic(topic, title, message, type = "info") {
  try {
    console.log("📤 Sending notification to topic:", topic);
    console.log("  Title:", title);
    console.log("  Message:", message);

    const payload = {
      topic: topic,
      notification: {
        title: title,
        body: message,
      },
      data: {
        title: title,
        body: message,
        message: message,
        type: type,
        timestamp: new Date().toISOString(),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nhs_dangbo_high_importance",
          priority: "high",
          sound: "default",
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
          },
        },
      },
    };

    const response = await admin.messaging().send(payload);
    console.log("✅ Notification sent to topic successfully!");
    console.log("  Message ID:", response);
    return response;
  } catch (error) {
    console.error("❌ Error sending notification to topic:", error);
    throw error;
  }
}

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 4) {
    console.log(
      "❌ Usage: node send_notification_with_fcm.js <userId> <fcmToken> <title> <message> [type]"
    );
    console.log("");
    console.log("Example:");
    console.log(
      '  node send_notification_with_fcm.js Aa07GEX3GbVS8Dc6kOuGaY4Z5x22 "cXXXXXXXX..." "Test" "Hello from FCM!" info'
    );
    console.log("");
    console.log("Or send to topic:");
    console.log(
      '  node send_notification_with_fcm.js --topic all "Test" "Hello everyone!"'
    );
    process.exit(1);
  }

  if (args[0] === "--topic") {
    const [, topic, title, message, type] = args;
    sendNotificationToTopic(topic, title, message, type || "info")
      .then(() => {
        console.log("");
        console.log("✅ Done!");
        process.exit(0);
      })
      .catch((error) => {
        console.error("❌ Failed:", error.message);
        process.exit(1);
      });
  } else {
    const [userId, fcmToken, title, message, type] = args;
    sendNotificationToDevice(userId, fcmToken, title, message, type || "info")
      .then(() => {
        console.log("");
        console.log("✅ Done!");
        console.log(
          "💡 Check your device - notification should appear even if app is closed!"
        );
        process.exit(0);
      })
      .catch((error) => {
        console.error("❌ Failed:", error.message);
        process.exit(1);
      });
  }
}

module.exports = {
  sendNotificationToDevice,
  sendNotificationToTopic,
};
