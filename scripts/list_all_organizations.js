/**
 * Script to list all organization names in the database
 * This will help us see the exact names to create proper mapping
 */

const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

// Initialize Firebase Admin (check if already initialized)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function listAllOrganizations() {
  try {
    console.log("🔍 Fetching all organizations from database...\n");

    const snapshot = await db.collection("to_chuc_dang").get();

    if (snapshot.empty) {
      console.log("⚠️  No organizations found in database");
      return;
    }

    console.log(`📊 Found ${snapshot.size} organizations\n`);
    console.log("=".repeat(80));
    console.log("LIST OF ALL ORGANIZATIONS IN DATABASE:");
    console.log("=".repeat(80));

    const organizations = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      organizations.push({
        id: doc.id,
        name: data.name,
        type: data.type || "N/A",
        stt: data.stt || "Not set",
      });
    });

    // Sort by current STT if exists, otherwise by name
    organizations.sort((a, b) => {
      if (a.stt !== "Not set" && b.stt !== "Not set") {
        return a.stt - b.stt;
      }
      return a.name.localeCompare(b.name, "vi");
    });

    // Print all organizations
    organizations.forEach((org, index) => {
      console.log(`\n${index + 1}. STT: ${org.stt}`);
      console.log(`   Name: "${org.name}"`);
      console.log(`   Type: ${org.type}`);
    });

    console.log("\n" + "=".repeat(80));
    console.log("COPY THIS TO UPDATE THE MAPPING:");
    console.log("=".repeat(80));

    organizations.forEach((org, index) => {
      // Clean name suggestions
      let cleanedName = org.name;
      cleanedName = cleanedName.replace(/\s*\(khu vực[^)]*\)/g, "").trim();
      cleanedName = cleanedName.replace(/\s*\(cơ sở\)/g, "").trim();
      cleanedName = cleanedName.replace(/\s+/g, " ").trim();

      console.log(`  '${cleanedName}': ${index + 1}, // Original: ${org.name}`);
    });

    process.exit(0);
  } catch (error) {
    console.error("❌ Error listing organizations:", error);
    process.exit(1);
  }
}

// Run the script
listAllOrganizations();
