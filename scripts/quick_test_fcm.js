#!/usr/bin/env node

/**
 * Quick test: Send FCM notification to check if it arrives when app is killed
 *
 * Usage:
 *   node quick_test_fcm.js <userId>
 *
 * Example:
 *   node quick_test_fcm.js 0aprehFSjDWCUxwnxVRYiYZe1Ap1
 */

const admin = require("firebase-admin");
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

async function quickTest(userId) {
  try {
    console.log("");
    console.log("🧪 ========================================");
    console.log("   QUICK FCM TEST - App Killed/Background");
    console.log("========================================");
    console.log("");

    // Get FCM token
    console.log("📱 Getting FCM token from Firestore...");
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
      console.log("");
      console.log("❌ USER KHÔNG CÓ FCM TOKEN!");
      console.log("");
      console.log("📝 Hướng dẫn:");
      console.log("  1. Mở app trên điện thoại");
      console.log("  2. Đăng nhập bằng tài khoản này");
      console.log("  3. Đợi 5 giây");
      console.log("  4. Chạy lại script này");
      console.log("");
      process.exit(1);
    }

    console.log("✅ Found FCM token:", fcmToken.substring(0, 30) + "...");
    console.log("");

    // Send test notification
    console.log("📤 Sending FCM test notification...");
    console.log("");

    const timestamp = new Date().toLocaleTimeString("vi-VN");

    const fcmResponse = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "🧪 FCM Test - App Killed",
        body: `Test lúc ${timestamp} - Nếu nhận được, FCM hoạt động tốt!`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "test",
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
              title: "🧪 FCM Test - App Killed",
              body: `Test lúc ${timestamp} - Nếu nhận được, FCM hoạt động tốt!`,
            },
            sound: "default",
            badge: 1,
            category: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
      },
    });

    console.log("✅ FCM notification sent successfully!");
    console.log("   Message ID:", fcmResponse);
    console.log("");
    console.log("📱 ========================================");
    console.log("   KIỂM TRA ĐIỆN THOẠI NGAY!");
    console.log("========================================");
    console.log("");
    console.log("✅ Nếu THẤY thông báo:");
    console.log("   → FCM hoạt động TỐT!");
    console.log("   → Vấn đề có thể do battery optimization hoặc autostart");
    console.log("   → Xem file: docs/FIX_NOTIFICATION_WHEN_APP_KILLED.md");
    console.log("");
    console.log("❌ Nếu KHÔNG thấy thông báo sau 10 giây:");
    console.log("   1. Kiểm tra user đã cấp quyền notification chưa");
    console.log("   2. Kiểm tra điện thoại có internet không");
    console.log("   3. Kiểm tra Google Play Services đã update chưa");
    console.log("   4. TẮT battery optimization cho app");
    console.log("   5. BẬT autostart cho app (Xiaomi, Oppo, Vivo)");
    console.log("");
    console.log("📋 Xem hướng dẫn chi tiết:");
    console.log("   docs/FIX_NOTIFICATION_WHEN_APP_KILLED.md");
    console.log("");
  } catch (error) {
    console.error("");
    console.error("❌ ERROR:", error.message);
    console.error("");
    process.exit(1);
  }
}

// Get userId from command line
const userId = process.argv[2];

if (!userId) {
  console.error("");
  console.error("❌ Usage: node quick_test_fcm.js <userId>");
  console.error("");
  console.error("Example:");
  console.error("  node quick_test_fcm.js 0aprehFSjDWCUxwnxVRYiYZe1Ap1");
  console.error("");
  process.exit(1);
}

quickTest(userId);
