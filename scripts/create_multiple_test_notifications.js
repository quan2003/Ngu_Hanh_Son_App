/**
 * Create Multiple Test Notifications in Supabase
 * Tạo nhiều thông báo test để kiểm tra hệ thống
 */

const { createClient } = require("@supabase/supabase-js");

// Supabase credentials
const SUPABASE_URL = "https://aehsrxzaewvoxatzqdca.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaHNyeHphZXd2b3hhdHpxZGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMzczNTIsImV4cCI6MjA3NzYxMzM1Mn0.oRtIqcoqcRH3RsFpTO5Ze0ZEgt2LThO3dTPwJ3X9k0g";

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function createMultipleNotifications() {
  try {
    console.log("🧪 Creating Multiple Test Notifications...\n");

    // Test user ID
    const testUserId = "Aa07GEX3GbVS8Dc6kOuGaY4Z5x22";

    console.log(`✅ Using Firebase User ID: ${testUserId}`);

    // Create 5 different test notifications
    const notifications = [
      {
        user_id: testUserId,
        title: "📝 Thông báo quan trọng",
        message: "Bạn có một nhiệm vụ mới cần xử lý",
        body: "Bạn có một nhiệm vụ mới cần xử lý",
        type: "info",
        read: false,
        metadata: { source: "test_script", priority: "high" },
      },
      {
        user_id: testUserId,
        title: "✅ Hoàn thành nhiệm vụ",
        message: "Nhiệm vụ của bạn đã được hoàn thành thành công",
        body: "Nhiệm vụ của bạn đã được hoàn thành thành công",
        type: "success",
        read: false,
        metadata: { source: "test_script", taskId: "task_001" },
      },
      {
        user_id: testUserId,
        title: "⚠️ Cảnh báo hệ thống",
        message: "Có một vấn đề cần được xem xét",
        body: "Có một vấn đề cần được xem xét",
        type: "warning",
        read: false,
        metadata: { source: "test_script", level: "medium" },
      },
      {
        user_id: testUserId,
        title: "📢 Thông báo chung",
        message: "Hệ thống sẽ bảo trì vào ngày mai",
        body: "Hệ thống sẽ bảo trì vào ngày mai",
        type: "announcement",
        read: false,
        metadata: { source: "test_script", date: "2025-11-03" },
      },
      {
        user_id: testUserId,
        title: "🎉 Chúc mừng!",
        message: "Bạn đã đạt được thành tựu mới",
        body: "Bạn đã đạt được thành tựu mới",
        type: "success",
        read: false,
        metadata: { source: "test_script", achievement: "level_up" },
      },
    ];

    console.log(`📤 Creating ${notifications.length} notifications...\n`);

    for (let i = 0; i < notifications.length; i++) {
      const notif = notifications[i];
      const { data, error } = await supabase
        .from("notifications")
        .insert([notif])
        .select();

      if (error) {
        console.error(
          `❌ Error creating notification ${i + 1}:`,
          error.message
        );
        continue;
      }

      console.log(`✅ ${i + 1}/${notifications.length}: ${notif.title}`);

      // Wait a bit between insertions for Supabase realtime to process
      await new Promise((resolve) => setTimeout(resolve, 500));
    }

    console.log(`\n✅ All notifications created successfully!`);

    // Get total count
    const { data: allNotifs, error: listError } = await supabase
      .from("notifications")
      .select("*")
      .eq("user_id", testUserId)
      .order("created_at", { ascending: false });

    if (!listError) {
      console.log(`\n📊 Total notifications: ${allNotifs.length}`);
      console.log(`📬 Unread: ${allNotifs.filter((n) => !n.read).length}`);

      console.log(`\n📋 Latest notifications:`);
      allNotifs.slice(0, 5).forEach((notif, index) => {
        const status = notif.read ? "✅" : "📩";
        console.log(`  ${index + 1}. ${status} ${notif.title} - ${notif.type}`);
      });
    }
  } catch (error) {
    console.error("❌ Error:", error);
  }
}

// Run the function
createMultipleNotifications();
