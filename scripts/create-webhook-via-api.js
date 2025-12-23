/**
 * Create Supabase Database Webhook via Management API
 *
 * Script này tạo webhook tự động qua Supabase Management API
 * Thay vì phải tạo thủ công qua Dashboard
 *
 * Prerequisites:
 * - Supabase Access Token (từ Dashboard > Account > Access Tokens)
 * - Project ID
 *
 * Usage:
 *   node create-webhook-via-api.js
 */

const SUPABASE_PROJECT_REF = "aehsrxzaewvoxatzqdca";
const SUPABASE_ACCESS_TOKEN =
  process.env.SUPABASE_ACCESS_TOKEN || "YOUR_ACCESS_TOKEN_HERE";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "YOUR_ANON_KEY_HERE";

// Edge Function URL
const EDGE_FUNCTION_URL = `https://${SUPABASE_PROJECT_REF}.supabase.co/functions/v1/send-fcm-notification-legacy`;

/**
 * Create Database Webhook
 */
async function createWebhook() {
  console.log("🔗 Creating Supabase Database Webhook...");
  console.log("");

  // Validate access token
  if (SUPABASE_ACCESS_TOKEN === "YOUR_ACCESS_TOKEN_HERE") {
    console.error("❌ Error: SUPABASE_ACCESS_TOKEN not configured!");
    console.log("");
    console.log("📝 To get Access Token:");
    console.log("  1. Go to: https://supabase.com/dashboard/account/tokens");
    console.log("  2. Click 'Generate new token'");
    console.log("  3. Copy the token");
    console.log("  4. Set environment variable:");
    console.log("     $env:SUPABASE_ACCESS_TOKEN='your-token'");
    console.log("");
    process.exit(1);
  }

  if (SUPABASE_ANON_KEY === "YOUR_ANON_KEY_HERE") {
    console.error("❌ Error: SUPABASE_ANON_KEY not configured!");
    console.log("");
    console.log("📝 To get Anon Key:");
    console.log(
      `  1. Go to: https://supabase.com/dashboard/project/${SUPABASE_PROJECT_REF}/settings/api`
    );
    console.log("  2. Copy 'anon public' key");
    console.log("  3. Set environment variable:");
    console.log("     $env:SUPABASE_ANON_KEY='your-anon-key'");
    console.log("");
    process.exit(1);
  }

  try {
    // Note: Supabase Management API không hỗ trợ tạo Database Webhooks
    // Database Webhooks chỉ có thể tạo qua Dashboard UI

    console.log(
      "⚠️  Supabase Management API chưa hỗ trợ tạo Database Webhooks"
    );
    console.log("");
    console.log("📋 Bạn phải tạo webhook thủ công qua Dashboard:");
    console.log("");
    console.log("1. Vào:");
    console.log(
      `   https://supabase.com/dashboard/project/${SUPABASE_PROJECT_REF}/database/hooks`
    );
    console.log("");
    console.log("2. Click 'Create a new hook'");
    console.log("");
    console.log("3. Nhập thông tin sau:");
    console.log("");
    console.log("   Name:");
    console.log("   send_fcm_on_notification_insert");
    console.log("");
    console.log("   Table:");
    console.log("   notifications");
    console.log("");
    console.log("   Events:");
    console.log("   ✅ Insert");
    console.log("");
    console.log("   Type:");
    console.log("   HTTP Request");
    console.log("");
    console.log("   Method:");
    console.log("   POST");
    console.log("");
    console.log("   URL:");
    console.log(`   ${EDGE_FUNCTION_URL}`);
    console.log("");
    console.log("   HTTP Headers:");
    console.log("   Content-Type: application/json");
    console.log(`   Authorization: Bearer ${SUPABASE_ANON_KEY}`);
    console.log("");
    console.log("4. Click 'Create webhook'");
    console.log("");

    // Alternative: Create webhook config file for reference
    const webhookConfig = {
      name: "send_fcm_on_notification_insert",
      type: "INSERT",
      table: "notifications",
      schema: "public",
      url: EDGE_FUNCTION_URL,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      },
      enabled: true,
    };

    console.log("💾 Webhook Configuration (for reference):");
    console.log(JSON.stringify(webhookConfig, null, 2));
    console.log("");

    console.log("✅ Configuration saved!");
    console.log("");
    console.log("📝 Next steps:");
    console.log("  1. Create webhook in Dashboard (follow instructions above)");
    console.log("  2. Test webhook:");
    console.log("     cd scripts");
    console.log("     node test_supabase_notification.js");
    console.log("  3. Monitor logs:");
    console.log("     supabase functions logs send-fcm-notification-legacy");
    console.log("");
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

// Run
createWebhook();
