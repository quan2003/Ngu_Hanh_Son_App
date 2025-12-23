const admin = require("firebase-admin");

// Check if already initialized
if (admin.apps.length === 0) {
  const serviceAccount = require("../firebase-admin-key.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function quickCheck() {
  try {
    console.log("🔍 Kiểm tra kết nối Firestore...\n");

    // Test write
    console.log("✍️  Test write...");
    const testRef = db.collection("_test").doc("test");
    await testRef.set({ test: true, timestamp: Date.now() });
    console.log("✅ Write thành công\n");

    // Test read
    console.log("📖 Test read...");
    const testDoc = await testRef.get();
    console.log("✅ Read thành công:", testDoc.data());
    console.log("");

    // Check to_chuc_dang collection
    console.log("📊 Kiểm tra collection to_chuc_dang...");
    const snapshot = await db.collection("to_chuc_dang").limit(5).get();
    console.log(`✅ Tìm thấy ${snapshot.size} documents (limit 5)`);

    snapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`   - STT ${data.stt}: ${data.name}`);
    });

    // Count all
    console.log("\n📊 Đếm tổng số...");
    const allSnapshot = await db.collection("to_chuc_dang").get();
    console.log(`✅ Tổng số: ${allSnapshot.size} documents`);

    // Clean up test
    await testRef.delete();

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    process.exit(1);
  }
}

quickCheck();
