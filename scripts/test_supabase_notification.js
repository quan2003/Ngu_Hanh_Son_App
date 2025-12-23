/**
 * Test Supabase Notifications
 * Tạo notification test để kiểm tra hệ thống
 */

const { createClient } = require("@supabase/supabase-js");

// Supabase credentials
const SUPABASE_URL = "https://aehsrxzaewvoxatzqdca.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaHNyeHphZXd2b3hhdHpxZGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMzczNTIsImV4cCI6MjA3NzYxMzM1Mn0.oRtIqcoqcRH3RsFpTO5Ze0ZEgt2LThO3dTPwJ3X9k0g";

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testNotificationCreation() {
  try {
    console.log("🧪 Testing Supabase Notification Creation...\n"); // Test user ID (từ log: 👤 HOME: Current user: Aa07GEX3GbVS8Dc6kOuGaY4Z5x22)
    const testUserId = "Aa07GEX3GbVS8Dc6kOuGaY4Z5x22";

    console.log(`✅ Using Firebase User ID: ${testUserId}`);

    // Create test notification
    const { data, error } = await supabase
      .from("notifications")
      .insert([
        {
          user_id: testUserId,
          title: "🎉 Test Notification",
          message: "Đây là thông báo test từ Supabase",
          body: "Đây là thông báo test từ Supabase",
          type: "info",
          read: false,
          metadata: {
            source: "test_script",
            timestamp: new Date().toISOString(),
          },
        },
      ])
      .select();

    if (error) {
      console.error("❌ Lỗi tạo notification:", error.message);
      console.error("Chi tiết:", error);
      return;
    }

    console.log("✅ Notification đã được tạo thành công!");
    console.log("📝 Dữ liệu:", JSON.stringify(data, null, 2));

    // Get unread count
    const { data: unreadData, error: countError } = await supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("user_id", testUserId)
      .eq("read", false);

    if (countError) {
      console.error("⚠️ Lỗi đếm unread:", countError.message);
    } else {
      console.log(`\n📊 Số thông báo chưa đọc: ${unreadData?.length || 0}`);
    }

    // Get all user notifications
    const { data: allNotifs, error: listError } = await supabase
      .from("notifications")
      .select("*")
      .eq("user_id", testUserId)
      .order("created_at", { ascending: false })
      .limit(5);

    if (listError) {
      console.error("⚠️ Lỗi lấy danh sách:", listError.message);
    } else {
      console.log(`\n📬 5 thông báo gần nhất:`);
      allNotifs?.forEach((notif, index) => {
        console.log(
          `  ${index + 1}. ${notif.title} - ${notif.read ? "✅" : "📩"} ${
            notif.type
          }`
        );
      });
    }
  } catch (error) {
    console.error("❌ Lỗi:", error);
  }
}

// Run the test
testNotificationCreation();
