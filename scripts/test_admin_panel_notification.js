/**
 * Test sending notification via Admin Panel flow
 * This simulates: Admin Panel → Supabase → Webhook → FCM
 */

const { createClient } = require("@supabase/supabase-js");

// Initialize Supabase (update with your credentials)
const SUPABASE_URL =
  process.env.SUPABASE_URL || "https://your-project.supabase.co";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "your-anon-key";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testAdminPanelFlow() {
  const userId = process.argv[2] || "lEIFKpXp0eOAlT3Owf5xI48M3ib2";
  const title = process.argv[3] || "Test Admin Panel Flow";
  const message =
    process.argv[4] ||
    "Nếu nhận được thông báo này, Admin Panel → Webhook → FCM hoạt động!";
  const type = process.argv[5] || "info";

  console.log("🧪 Testing Admin Panel Flow...");
  console.log("═══════════════════════════════════════");
  console.log("📋 Test Info:");
  console.log(`  User ID: ${userId}`);
  console.log(`  Title: ${title}`);
  console.log(`  Message: ${message}`);
  console.log(`  Type: ${type}`);
  console.log("");

  try {
    // Step 1: Create notification in Supabase (giống như Admin Panel làm)
    console.log("1️⃣ Creating notification in Supabase...");

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
      throw new Error(`Supabase error: ${error.message}`);
    }

    console.log("✅ Notification created in Supabase!");
    console.log(`  Notification ID: ${data.id}`);
    console.log("");

    // Step 2: Webhook should trigger automatically
    console.log("2️⃣ Waiting for webhook to trigger...");
    console.log("  The webhook should:");
    console.log("    a) Detect new notification");
    console.log("    b) Get FCM token from Firestore");
    console.log("    c) Send FCM notification");
    console.log("");
    console.log("⏳ Please wait 5 seconds...");

    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log("");
    console.log("═══════════════════════════════════════");
    console.log("✅ Test completed!");
    console.log("");
    console.log("📱 Check your phone:");
    console.log("  - App có thể đang mở, đóng, hoặc ở background");
    console.log("  - Notification nên xuất hiện trên notification tray");
    console.log("  - Nếu không thấy → Check webhook logs");
    console.log("");
    console.log("🔍 Debug commands:");
    console.log("  # Check Supabase logs");
    console.log("  supabase functions logs send-notification");
    console.log("");
    console.log("  # Check if webhook exists");
    console.log("  supabase functions list");
    console.log("");
  } catch (error) {
    console.error("");
    console.error("❌ ERROR:", error.message);
    console.error("");
    console.error("🔧 Troubleshooting:");
    console.error("  1. Check Supabase credentials in this script");
    console.error("  2. Check if notifications table exists");
    console.error("  3. Check if webhook is deployed");
    console.error("");
    process.exit(1);
  }
}

// Run test
testAdminPanelFlow();
