/**
 * Sync FCM tokens from Firestore to Supabase
 * This is needed so Edge Function can read tokens from Supabase
 */

const admin = require("firebase-admin");
const { createClient } = require("@supabase/supabase-js");
const serviceAccount = require("../firebase-admin-key.json");

const SUPABASE_URL = "https://aehsrxzaewvoxatzqdca.supabase.co";
const SUPABASE_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaHNyeHphZXd2b3hhdHpxZGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMzczNTIsImV4cCI6MjA3NzYxMzM1Mn0.oRtIqcoqcRH3RsFpTO5Ze0ZEgt2LThO3dTPwJ3X9k0g";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function syncTokens() {
  try {
    console.log("🔄 Syncing FCM tokens from Firestore to Supabase...");
    console.log("");

    // Get all users from Firestore
    const usersSnapshot = await db.collection("users").get();

    let synced = 0;
    let skipped = 0;

    for (const doc of usersSnapshot.docs) {
      const userId = doc.id;
      const userData = doc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`⏭️  Skipping ${userData.email} - no FCM token`);
        skipped++;
        continue;
      }

      // Upsert to Supabase
      const { error } = await supabase.from("users").upsert({
        id: userId,
        fcm_token: fcmToken,
        fcm_token_updated_at: new Date().toISOString(),
      });

      if (error) {
        console.error(`❌ Error syncing ${userData.email}: ${error.message}`);
      } else {
        console.log(`✅ Synced ${userData.email}`);
        synced++;
      }
    }

    console.log("");
    console.log("📊 Summary:");
    console.log(`  ✅ Synced: ${synced}`);
    console.log(`  ⏭️  Skipped: ${skipped}`);
    console.log(`  📱 Total: ${usersSnapshot.docs.length}`);
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

syncTokens();
