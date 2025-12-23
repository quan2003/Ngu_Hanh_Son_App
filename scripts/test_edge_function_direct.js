/**
 * Test calling Edge Function directly (bypass webhook)
 * This simulates what Flutter app does when sending notification
 */

const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehsrxzaewvoxatzqdca.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaHNyeHphZXd2b3hhdHpxZGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMzczNTIsImV4cCI6MjA3NzYxMzM1Mn0.oRtIqcoqcRH3RsFpTO5Ze0ZEgt2LThO3dTPwJ3X9k0g";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testEdgeFunction(userId, title, message) {
  try {
    console.log("🧪 Testing Edge Function direct call...");
    console.log(`📤 User: ${userId}`);
    console.log(`📋 Title: ${title}`);
    console.log(`💬 Message: ${message}`);
    console.log("");

    // Step 1: Insert notification into Supabase
    console.log("1️⃣ Inserting notification into Supabase...");
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

    console.log("✅ Notification inserted:", notification.id);
    console.log("");

    // Step 2: Call Edge Function directly
    console.log("2️⃣ Calling Edge Function directly...");
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
    console.log("📱 Check your phone!");
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

// Get command line arguments
const userId = process.argv[2];
const title = process.argv[3] || "Test Direct Call";
const message = process.argv[4] || "Testing Edge Function directly from script";

if (!userId) {
  console.log("Usage:");
  console.log("  node test_edge_function_direct.js <userId> [title] [message]");
  console.log("");
  console.log("Example:");
  console.log(
    '  node test_edge_function_direct.js lEIFKpXp0eOAlT3Owf5xI48M3ib2 "Test" "App killed"'
  );
  process.exit(1);
}

testEdgeFunction(userId, title, message);
