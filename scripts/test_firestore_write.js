const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function testWrite() {
  console.log("🧪 Testing Firestore write...\n");

  try {
    // Test write một document đơn giản
    const testRef = db.collection("to_chuc_dang").doc("test_doc");

    console.log("📝 Writing test document...");
    await testRef.set({
      id: "test_doc",
      stt: 999,
      name: "Test Organization",
      totalMembers: 100,
      officialMembers: 90,
      probationaryMembers: 10,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Write successful!\n");

    // Read back để verify
    console.log("📖 Reading back test document...");
    const doc = await testRef.get();

    if (doc.exists) {
      console.log("✅ Document exists!");
      console.log("📄 Data:", doc.data());
    } else {
      console.log("❌ Document does not exist after write!");
    }

    // List all documents
    console.log("\n📋 Listing all documents in collection...");
    const snapshot = await db.collection("to_chuc_dang").get();
    console.log(`   Found ${snapshot.size} documents`);

    // Delete test document
    console.log("\n🗑️  Deleting test document...");
    await testRef.delete();
    console.log("✅ Test document deleted\n");
  } catch (error) {
    console.error("❌ Error:", error);
  }

  process.exit(0);
}

testWrite();
