const admin = require("firebase-admin");
const path = require("path");

// Initialize Firebase A    // Also create notification records in Firestore
console.log("\n📝 Creating notification records in Firestore...");
for (const userId of userIds) {
  await db.collection("notifications").add({
    userId: userId,
    title: "🎉 Thông báo thử nghiệm",
    message:
      "Hệ thống thông báo đẩy đang hoạt động tốt! Bạn sẽ nhận được các thông báo quan trọng từ Đảng Bộ Phường Ngũ Hành Sơn.",
    type: "announcement",
    isRead: false,
    actionUrl: null,
    createdAt: admin.firestore.Timestamp.now(),
  });
}
console.log("✅ Notification records created in Firestore");
rviceAccount = require(path.join(__dirname, "..", "firebase-admin-key.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

async function sendTestNotification() {
  try {
    console.log("🚀 Starting to send test push notification...\n");

    // Get all users (simpler query without compound index)
    const usersSnapshot = await db.collection("users").get();

    if (usersSnapshot.empty) {
      console.log("❌ No users found");
      return;
    }

    console.log(`📧 Found ${usersSnapshot.size} user(s) total\n`);

    // Filter users with FCM tokens and notifications enabled in memory
    const tokens = [];
    const userEmails = [];
    const userIds = [];

    usersSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (data.fcmToken && data.notificationsEnabled === true) {
        tokens.push(data.fcmToken);
        userEmails.push(data.email);
        userIds.push(doc.id);
      }
    });

    if (tokens.length === 0) {
      console.log("❌ No users with FCM tokens and notifications enabled");
      console.log(
        "💡 Make sure users have enabled notifications in app settings"
      );
      return;
    }

    console.log(
      `✅ Found ${tokens.length} user(s) with notifications enabled\n`
    );

    // Send notification
    const message = {
      notification: {
        title: "🎉 Thông báo thử nghiệm",
        body: "Hệ thống thông báo đẩy đang hoạt động tốt! Bạn sẽ nhận được các thông báo quan trọng từ Đảng Bộ Phường Ngũ Hành Sơn.",
      },
      data: {
        action: "test",
        timestamp: new Date().toISOString(),
        type: "announcement",
      },
      tokens: tokens,
      android: {
        priority: "high",
        notification: {
          channelId: "nhs_dangbo_high_importance",
          sound: "default",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);

    console.log(`✅ Successfully sent: ${response.successCount}`);
    console.log(`❌ Failed: ${response.failureCount}`);

    if (response.failureCount > 0) {
      console.log("\n❌ Failed tokens:");
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.log(`  - ${userEmails[idx]}: ${resp.error?.message}`);
        }
      });
    }

    console.log("\n✨ Test notification completed!\n");
    console.log("Recipients:");
    userEmails.forEach((email, idx) => {
      const status = response.responses[idx].success ? "✅" : "❌";
      console.log(`  ${status} ${email}`);
    });

    // Also create notification record in Firestore
    console.log("\n📝 Creating notification records in Firestore...");
    for (const userId of usersSnapshot.docs.map((doc) => doc.id)) {
      await db.collection("notifications").add({
        userId: userId,
        title: "🎉 Thông báo thử nghiệm",
        message:
          "Hệ thống thông báo đẩy đang hoạt động tốt! Bạn sẽ nhận được các thông báo quan trọng từ Đảng Bộ Phường Ngũ Hành Sơn.",
        type: "announcement",
        isRead: false,
        actionUrl: null,
        createdAt: admin.firestore.Timestamp.now(),
      });
    }
    console.log("✅ Notification records created in Firestore");
  } catch (error) {
    console.error("❌ Error sending test notification:", error);
  } finally {
    process.exit(0);
  }
}

// Run the function
sendTestNotification();
