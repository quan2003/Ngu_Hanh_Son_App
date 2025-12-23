#!/usr/bin/env node

/**
 * Script to manage admin emails in Firebase
 *
 * Usage:
 *   node manage_admins.js list                    - Show all admins
 *   node manage_admins.js add <email>             - Add new admin
 *   node manage_admins.js remove <email>          - Remove admin
 *   node manage_admins.js reset                   - Reset to defaults
 */

const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

// Initialize Firebase Admin
const serviceAccountPath = path.join(
  __dirname,
  "..",
  "firebase-admin-key.json"
);

if (!fs.existsSync(serviceAccountPath)) {
  console.error("❌ firebase-admin-key.json not found!");
  console.error(
    "   Please download the service account key from Firebase Console"
  );
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const CONFIG_COLLECTION = "config";
const ADMIN_CONFIG_DOC = "admin_emails";

const DEFAULT_ADMINS = ["admin@nhs.vn", "admin@gmail.com", "quanly@nhs.vn"];

/**
 * List all admin emails
 */
async function listAdmins() {
  try {
    const doc = await db
      .collection(CONFIG_COLLECTION)
      .doc(ADMIN_CONFIG_DOC)
      .get();

    if (!doc.exists) {
      console.log("⚠️  No admin config found. Using default admins:");
      console.log(DEFAULT_ADMINS.map((e, i) => `   ${i + 1}. ${e}`).join("\n"));
      return;
    }

    const data = doc.data();
    const emails = data?.emails || [];

    console.log(`\n👨‍💼 Current Admin List (${emails.length} admins):`);
    emails.forEach((email, index) => {
      console.log(`   ${index + 1}. ${email}`);
    });

    if (emails.length === 0) {
      console.log("   (empty)");
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

/**
 * Add new admin email
 */
async function addAdmin(email) {
  try {
    if (!email || !email.includes("@")) {
      console.error("❌ Invalid email format");
      process.exit(1);
    }

    const emailLower = email.toLowerCase().trim();

    // Get current admins
    const doc = await db
      .collection(CONFIG_COLLECTION)
      .doc(ADMIN_CONFIG_DOC)
      .get();
    const currentEmails = doc.exists
      ? doc.data()?.emails || []
      : [...DEFAULT_ADMINS];

    if (currentEmails.includes(emailLower)) {
      console.log(`⚠️  "${emailLower}" is already an admin`);
      return;
    }

    // Add new admin
    await db
      .collection(CONFIG_COLLECTION)
      .doc(ADMIN_CONFIG_DOC)
      .set(
        {
          emails: [...currentEmails, emailLower],
          updatedAt: new Date(),
        },
        { merge: true }
      );

    console.log(`✅ Admin added successfully: ${emailLower}`);
    console.log(`\n📋 Updated admin list:`);
    const newEmails = [...currentEmails, emailLower];
    newEmails.forEach((e, i) => {
      console.log(`   ${i + 1}. ${e}`);
    });
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

/**
 * Remove admin email
 */
async function removeAdmin(email) {
  try {
    if (!email) {
      console.error("❌ Email required");
      process.exit(1);
    }

    const emailLower = email.toLowerCase().trim();

    // Get current admins
    const doc = await db
      .collection(CONFIG_COLLECTION)
      .doc(ADMIN_CONFIG_DOC)
      .get();
    const currentEmails = doc.exists
      ? doc.data()?.emails || []
      : [...DEFAULT_ADMINS];

    if (!currentEmails.includes(emailLower)) {
      console.log(`⚠️  "${emailLower}" is not in admin list`);
      return;
    }

    // Remove admin
    const filteredEmails = currentEmails.filter((e) => e !== emailLower);

    await db.collection(CONFIG_COLLECTION).doc(ADMIN_CONFIG_DOC).set(
      {
        emails: filteredEmails,
        updatedAt: new Date(),
      },
      { merge: true }
    );

    console.log(`✅ Admin removed successfully: ${emailLower}`);
    console.log(`\n📋 Updated admin list:`);
    filteredEmails.forEach((e, i) => {
      console.log(`   ${i + 1}. ${e}`);
    });
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

/**
 * Reset to default admins
 */
async function resetAdmins() {
  try {
    console.log("⚠️  Resetting admin list to defaults...");

    await db.collection(CONFIG_COLLECTION).doc(ADMIN_CONFIG_DOC).set(
      {
        emails: DEFAULT_ADMINS,
        updatedAt: new Date(),
      },
      { merge: true }
    );

    console.log(`✅ Admin list reset successfully`);
    console.log(`\n📋 Default admin list:`);
    DEFAULT_ADMINS.forEach((e, i) => {
      console.log(`   ${i + 1}. ${e}`);
    });
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

/**
 * Main function
 */
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  try {
    switch (command) {
      case "list":
        await listAdmins();
        break;
      case "add":
        if (!args[1]) {
          console.error("❌ Email required: node manage_admins.js add <email>");
          process.exit(1);
        }
        await addAdmin(args[1]);
        break;
      case "remove":
        if (!args[1]) {
          console.error(
            "❌ Email required: node manage_admins.js remove <email>"
          );
          process.exit(1);
        }
        await removeAdmin(args[1]);
        break;
      case "reset":
        await resetAdmins();
        break;
      default:
        console.log("❌ Unknown command: " + command);
        console.log("\nUsage:");
        console.log(
          "  node manage_admins.js list                - Show all admins"
        );
        console.log(
          "  node manage_admins.js add <email>         - Add new admin"
        );
        console.log(
          "  node manage_admins.js remove <email>      - Remove admin"
        );
        console.log(
          "  node manage_admins.js reset               - Reset to defaults"
        );
        process.exit(1);
    }

    process.exit(0);
  } catch (error) {
    console.error("❌ Unexpected error:", error);
    process.exit(1);
  }
}

main();
