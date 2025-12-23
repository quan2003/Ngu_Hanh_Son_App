/**
 * Test sending notification via Supabase
 * This will INSERT into notifications table → Trigger Edge Function → Send FCM
 */

const { createClient } = require("@supabase/supabase-js");

// TODO: Update these with your Supabase credentials
const SUPABASE_URL =
  process.env.SUPABASE_URL || "https://your-project.supabase.co";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "your-anon-key";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testViaSupabase(userId, title, message, type = "info") {
  try {
    console.log("🧪 Testing notification via Supabase...");
    console.log(`📤 User: ${userId}`);
    console.log(`📋 Title: ${title}`);
    console.log(`💬 Message: ${message}`);
    console.log("");

    // Insert notification into Supabase
    // This will trigger the Edge Function webhook
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
      console.error("❌ Supabase error:", error.message);
      return;
    }

    console.log("✅ Notification inserted into Supabase!");
    console.log("🔔 ID:", data.id);
    console.log("");
    console.log("⏳ Webhook should trigger Edge Function now...");
    console.log("⏳ Edge Function will send FCM notification...");
    console.log("");
    console.log("📱 Check your phone! (even if app is closed)");
    console.log("");
    console.log("💡 To check logs:");
    console.log("   supabase functions logs send-fcm-notification");
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

// Get command line arguments
const userId = process.argv[2];
const title = process.argv[3];
const message = process.argv[4];
const type = process.argv[5] || "info";

if (!userId || !title || !message) {
  console.log("Usage:");
  console.log("  node test_via_supabase.js <userId> <title> <message> [type]");
  console.log("");
  console.log("Example:");
  console.log(
    '  node test_via_supabase.js lEIFKpXp0eOAlT3Owf5xI48M3ib2 "Test Supabase" "App đã tắt" info'
  );
  process.exit(1);
}

// Update Supabase credentials first!
if (SUPABASE_URL === "https://your-project.supabase.co") {
  console.error("❌ Please update SUPABASE_URL in the script!");
  console.log("💡 Set environment variables:");
  console.log('   $env:SUPABASE_URL="https://your-project.supabase.co"');
  console.log('   $env:SUPABASE_ANON_KEY="your-anon-key"');
  process.exit(1);
}

testViaSupabase(userId, title, message, type);
