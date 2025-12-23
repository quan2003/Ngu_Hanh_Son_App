/**
 * List all users with their FCM tokens
 * Use this to find user IDs for sending notifications
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

async function listUsersWithFCM() {
  try {
    console.log("📋 Listing all users with FCM tokens...\n");

    const usersSnapshot = await admin.firestore().collection("users").get();

    if (usersSnapshot.empty) {
      console.log("❌ No users found in database");
      return;
    }

    const usersWithFCM = [];
    const usersWithoutFCM = [];

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const userInfo = {
        id: doc.id,
        email: userData.email || "N/A",
        name: userData.displayName || userData.name || "N/A",
        role: userData.role || "user",
        fcmToken: userData.fcmToken || null,
        notificationsEnabled: userData.notificationsEnabled !== false,
      };

      if (userInfo.fcmToken) {
        usersWithFCM.push(userInfo);
      } else {
        usersWithoutFCM.push(userInfo);
      }
    });

    // Display users WITH FCM token
    console.log("✅ USERS WITH FCM TOKEN (Can receive push notifications):");
    console.log("=".repeat(80));
    usersWithFCM.forEach((user, index) => {
      console.log(`\n${index + 1}. ${user.name} (${user.role})`);
      console.log(`   📧 Email: ${user.email}`);
      console.log(`   🆔 User ID: ${user.id}`);
      console.log(`   📱 FCM Token: ${user.fcmToken.substring(0, 30)}...`);
      console.log(
        `   🔔 Notifications: ${
          user.notificationsEnabled ? "Enabled" : "Disabled"
        }`
      );
    });

    console.log("\n" + "=".repeat(80));
    console.log(`✅ Total users with FCM token: ${usersWithFCM.length}\n`);

    // Display users WITHOUT FCM token
    if (usersWithoutFCM.length > 0) {
      console.log(
        "⚠️  USERS WITHOUT FCM TOKEN (Cannot receive push notifications):"
      );
      console.log("=".repeat(80));
      usersWithoutFCM.forEach((user, index) => {
        console.log(`\n${index + 1}. ${user.name} (${user.role})`);
        console.log(`   📧 Email: ${user.email}`);
        console.log(`   🆔 User ID: ${user.id}`);
        console.log(`   ❌ FCM Token: Not set`);
        console.log(`   💡 User needs to login to the app`);
      });

      console.log("\n" + "=".repeat(80));
      console.log(
        `⚠️  Total users without FCM token: ${usersWithoutFCM.length}\n`
      );
    }

    // Summary
    console.log("📊 SUMMARY:");
    console.log("=".repeat(80));
    console.log(`Total users: ${usersWithFCM.length + usersWithoutFCM.length}`);
    console.log(`✅ Can receive notifications: ${usersWithFCM.length}`);
    console.log(`❌ Cannot receive notifications: ${usersWithoutFCM.length}`);
    console.log("=".repeat(80));

    // Export to file for easy copy-paste
    const fs = require("fs");
    const outputPath = path.join(__dirname, "users-with-fcm.txt");

    let output = "USERS WITH FCM TOKEN\n";
    output += "=".repeat(80) + "\n\n";

    usersWithFCM.forEach((user, index) => {
      output += `${index + 1}. ${user.name}\n`;
      output += `   Email: ${user.email}\n`;
      output += `   User ID: ${user.id}\n`;
      output += `   Role: ${user.role}\n\n`;
    });

    fs.writeFileSync(outputPath, output, "utf8");
    console.log(`\n💾 User list saved to: ${outputPath}`);
    console.log(
      "   You can use this file to find user IDs for sending notifications\n"
    );
  } catch (error) {
    console.error("❌ Error listing users:", error);
  } finally {
    process.exit(0);
  }
}

// Run
listUsersWithFCM();
