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

const db = admin.firestore();

// Sample notifications
const notifications = [
  {
    title: "Thông báo quan trọng",
    message:
      "Hội nghị Đảng bộ sẽ được tổ chức vào ngày 15/11/2025. Vui lòng có mặt đúng giờ.",
    type: "announcement",
    isRead: false,
    actionUrl: null,
    createdAt: admin.firestore.Timestamp.now(),
  },
  {
    title: "Cập nhật thông tin",
    message:
      "Hệ thống đã được cập nhật với nhiều tính năng mới. Vui lòng kiểm tra.",
    type: "info",
    isRead: false,
    actionUrl: null,
    createdAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 2 * 60 * 60 * 1000)
    ), // 2 hours ago
  },
  {
    title: "Nhắc nhở",
    message:
      "Bạn có nhiệm vụ cần hoàn thành trong tuần này. Vui lòng kiểm tra lại.",
    type: "warning",
    isRead: true,
    actionUrl: null,
    createdAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000)
    ), // 1 day ago
  },
  {
    title: "Hoàn thành",
    message: "Báo cáo tháng 10 của bạn đã được phê duyệt thành công.",
    type: "success",
    isRead: true,
    actionUrl: null,
    createdAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
    ), // 3 days ago
  },
  {
    title: "Lỗi hệ thống",
    message: "Đã xảy ra lỗi khi đồng bộ dữ liệu. Vui lòng thử lại sau.",
    type: "error",
    isRead: false,
    actionUrl: null,
    createdAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 5 * 60 * 1000)
    ), // 5 minutes ago
  },
];

async function addNotifications() {
  try {
    console.log("🚀 Starting to add sample notifications...\n");

    // Get first user from users collection
    const usersSnapshot = await db.collection("users").limit(1).get();

    if (usersSnapshot.empty) {
      console.error(
        "❌ No users found in database. Please create a user first."
      );
      return;
    }

    const userId = usersSnapshot.docs[0].id;
    const userEmail = usersSnapshot.docs[0].data().email;

    console.log(`📧 Adding notifications for user: ${userEmail} (${userId})\n`);

    // Add notifications for the user
    for (const notification of notifications) {
      const notificationData = {
        ...notification,
        userId: userId,
      };

      const docRef = await db.collection("notifications").add(notificationData);
      console.log(
        `✅ Added notification: ${notification.title} (${docRef.id})`
      );
    }

    // Add one broadcast notification (for all users)
    const broadcastNotification = {
      title: "Thông báo chung",
      message:
        "Chúc mừng các đồng chí nhân dịp Quốc khánh 30/4. Kính chúc sức khỏe và thành công!",
      type: "announcement",
      isRead: false,
      actionUrl: null,
      userId: "all", // broadcast to all users
      createdAt: admin.firestore.Timestamp.now(),
    };

    const broadcastRef = await db
      .collection("notifications")
      .add(broadcastNotification);
    console.log(
      `\n📢 Added broadcast notification: ${broadcastNotification.title} (${broadcastRef.id})`
    );

    console.log("\n✨ All sample notifications added successfully!\n");
    console.log(`Total notifications: ${notifications.length + 1}`);
    console.log(`  - Personal: ${notifications.length}`);
    console.log(`  - Broadcast: 1`);
  } catch (error) {
    console.error("❌ Error adding notifications:", error);
  } finally {
    process.exit(0);
  }
}

// Run the function
addNotifications();
