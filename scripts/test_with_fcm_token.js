/**
 * Test Edge Function with FCM token in payload
 * This bypasses the need to fetch token from Firestore
 */

const { createClient } = require("@supabase/supabase-js");
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

const SUPABASE_URL = "https://aehsrxzaewvoxatzqdca.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaHNyeHphZXd2b3hhdHpxZGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMzczNTIsImV4cCI6MjA3NzYxMzM1Mn0.oRtIqcoqcRH3RsFpTO5Ze0ZEgt2LThO3dTPwJ3X9k0g";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testWithToken(userId, title, message) {
  try {
    console.log("🧪 Testing with FCM token in payload...");
    console.log(`📤 User: ${userId}`);
    console.log("");

    // Step 1: Get FCM token from Firestore
    console.log("1️⃣ Fetching FCM token from Firestore...");
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.error(`❌ User not found: ${userId}`);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      console.error(`❌ User has no FCM token: ${userId}`);
      return;
    }

    console.log(`✅ FCM Token: ${fcmToken.substring(0, 30)}...`);
    console.log("");

    // Step 2: Insert notification into Supabase
    console.log("2️⃣ Inserting notification into Supabase...");
    const { data: notification, error: insertError } = await supabase
      .from("notifications")
      .insert({
        user_id: userId,
        title: title,
        message: message,
        type: "info",
        read: false,
      })
      .select()
      .single();

    if (insertError) {
      console.error("❌ Insert error:", insertError.message);
      return;
    }

    console.log(`✅ Notification inserted: ${notification.id}`);
    console.log("");

    // Step 3: Call Edge Function WITH FCM token
    console.log("3️⃣ Calling Edge Function with FCM token...");
    const { data, error } = await supabase.functions.invoke(
      "send-fcm-notification",
      {
        body: {
          type: "INSERT",
          record: {
            id: notification.id,
            user_id: userId,
            title: title,
            message: message,
            body: message,
            type: "info",
            fcm_token: fcmToken, // Include FCM token!
          },
        },
      }
    );

    if (error) {
      console.error("❌ Edge Function error:", error);
      return;
    }

    console.log("✅ Edge Function response:", data);
    console.log("");
    console.log("📱 Check your phone! (even if app is closed)");
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

const userId = process.argv[2];
const title = process.argv[3] || "Test với Token";
const message = process.argv[4] || "Notification khi app tắt";

if (!userId) {
  console.log("Usage:");
  console.log("  node test_with_fcm_token.js <userId> [title] [message]");
  console.log("");
  console.log("Example:");
  console.log(
    '  node test_with_fcm_token.js lEIFKpXp0eOAlT3Owf5xI48M3ib2 "Test" "App killed"'
  );
  process.exit(1);
}

testWithToken(userId, title, message);
