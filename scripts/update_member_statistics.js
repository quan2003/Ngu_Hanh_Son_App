/**
 * Update party member statistics for all organizations
 */
const admin = require("firebase-admin");
const serviceAccount = require("../firebase-admin-key.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// Member statistics mapped by STT
const memberStats = {
  1: { total: 56, official: 56, probationary: 0 },
  2: { total: 242, official: 236, probationary: 6 },
  3: { total: 69, official: 54, probationary: 15 },
  4: { total: 42, official: 33, probationary: 9 },
  5: { total: 46, official: 35, probationary: 11 },
  6: { total: 23, official: 22, probationary: 1 },
  7: { total: 36, official: 27, probationary: 9 },
  8: { total: 12, official: 11, probationary: 1 },
  9: { total: 14, official: 14, probationary: 0 },
  10: { total: 18, official: 16, probationary: 2 },
  11: { total: 6, official: 6, probationary: 0 },
  12: { total: 8, official: 8, probationary: 0 },
  13: { total: 25, official: 20, probationary: 5 },
  14: { total: 4, official: 4, probationary: 0 },
  15: { total: 9, official: 7, probationary: 2 },
  16: { total: 15, official: 13, probationary: 2 },
  17: { total: 48, official: 38, probationary: 10 },
  18: { total: 27, official: 20, probationary: 7 },
  19: { total: 32, official: 28, probationary: 4 },
  20: { total: 36, official: 27, probationary: 9 },
  21: { total: 47, official: 38, probationary: 9 },
  22: { total: 27, official: 21, probationary: 6 },
  23: { total: 39, official: 30, probationary: 9 },
  24: { total: 36, official: 29, probationary: 7 },
  25: { total: 26, official: 20, probationary: 6 },
  26: { total: 29, official: 23, probationary: 6 },
  27: { total: 25, official: 21, probationary: 4 },
  28: { total: 19, official: 15, probationary: 4 },
  29: { total: 33, official: 27, probationary: 6 },
  30: { total: 22, official: 19, probationary: 3 },
  31: { total: 36, official: 33, probationary: 3 },
  32: { total: 3, official: 3, probationary: 0 },
  33: { total: 18, official: 14, probationary: 4 },
  34: { total: 14, official: 14, probationary: 0 },
  35: { total: 15, official: 11, probationary: 4 },
  36: { total: 31, official: 26, probationary: 5 },
  37: { total: 51, official: 49, probationary: 2 },
  38: { total: 47, official: 47, probationary: 0 },
  39: { total: 35, official: 35, probationary: 0 },
  40: { total: 36, official: 36, probationary: 0 },
  41: { total: 23, official: 21, probationary: 2 },
  42: { total: 33, official: 31, probationary: 2 },
  43: { total: 29, official: 29, probationary: 0 },
  44: { total: 25, official: 25, probationary: 0 },
  45: { total: 21, official: 21, probationary: 0 },
  46: { total: 51, official: 49, probationary: 2 },
  47: { total: 28, official: 28, probationary: 0 },
  48: { total: 26, official: 24, probationary: 2 },
  49: { total: 11, official: 11, probationary: 0 },
  50: { total: 41, official: 40, probationary: 1 },
  51: { total: 26, official: 25, probationary: 1 },
  52: { total: 27, official: 26, probationary: 1 },
  53: { total: 64, official: 64, probationary: 0 },
  54: { total: 49, official: 49, probationary: 0 },
  55: { total: 20, official: 20, probationary: 0 },
  56: { total: 25, official: 24, probationary: 1 },
  57: { total: 30, official: 30, probationary: 0 },
  58: { total: 18, official: 18, probationary: 0 },
  59: { total: 17, official: 17, probationary: 0 },
  60: { total: 23, official: 23, probationary: 0 },
  61: { total: 35, official: 34, probationary: 1 },
  62: { total: 16, official: 16, probationary: 0 },
  63: { total: 17, official: 17, probationary: 0 },
  64: { total: 50, official: 49, probationary: 1 },
  65: { total: 43, official: 42, probationary: 1 },
  66: { total: 23, official: 22, probationary: 1 },
  67: { total: 13, official: 13, probationary: 0 },
  68: { total: 25, official: 25, probationary: 0 },
  69: { total: 23, official: 22, probationary: 1 },
  70: { total: 30, official: 30, probationary: 0 },
  71: { total: 40, official: 39, probationary: 1 },
  72: { total: 27, official: 27, probationary: 0 },
  73: { total: 23, official: 22, probationary: 1 },
  74: { total: 39, official: 37, probationary: 2 },
  75: { total: 27, official: 27, probationary: 0 },
  76: { total: 22, official: 21, probationary: 1 },
  77: { total: 21, official: 21, probationary: 0 },
  78: { total: 21, official: 21, probationary: 0 },
  79: { total: 29, official: 27, probationary: 2 },
  80: { total: 17, official: 17, probationary: 0 },
  81: { total: 16, official: 16, probationary: 0 },
  82: { total: 29, official: 29, probationary: 0 },
  83: { total: 6, official: 5, probationary: 1 },
  84: { total: 22, official: 22, probationary: 0 },
  85: { total: 15, official: 15, probationary: 0 },
  86: { total: 40, official: 40, probationary: 0 },
  87: { total: 43, official: 42, probationary: 1 },
  88: { total: 43, official: 43, probationary: 0 },
  89: { total: 29, official: 29, probationary: 0 },
  90: { total: 19, official: 18, probationary: 1 },
  91: { total: 21, official: 20, probationary: 1 },
  92: { total: 28, official: 28, probationary: 0 },
  93: { total: 13, official: 12, probationary: 1 },
  94: { total: 111, official: 109, probationary: 2 },
  95: { total: 18, official: 18, probationary: 0 },
  96: { total: 29, official: 27, probationary: 2 },
  97: { total: 19, official: 17, probationary: 2 },
  98: { total: 19, official: 18, probationary: 1 },
  99: { total: 19, official: 18, probationary: 1 },
  100: { total: 17, official: 16, probationary: 1 },
  101: { total: 52, official: 50, probationary: 2 },
  102: { total: 19, official: 17, probationary: 2 },
  103: { total: 14, official: 12, probationary: 2 },
  104: { total: 20, official: 17, probationary: 3 },
  105: { total: 15, official: 15, probationary: 0 },
  106: { total: 34, official: 33, probationary: 1 },
  107: { total: 16, official: 15, probationary: 1 },
  108: { total: 36, official: 36, probationary: 0 },
  109: { total: 45, official: 45, probationary: 0 },
  110: { total: 62, official: 62, probationary: 0 },
  111: { total: 23, official: 22, probationary: 1 },
  112: { total: 18, official: 16, probationary: 2 },
  113: { total: 28, official: 28, probationary: 0 },
  114: { total: 50, official: 49, probationary: 1 },
  115: { total: 26, official: 25, probationary: 1 },
  116: { total: 30, official: 30, probationary: 0 },
  117: { total: 28, official: 27, probationary: 1 },
  118: { total: 19, official: 17, probationary: 2 },
  119: { total: 38, official: 34, probationary: 4 },
  120: { total: 27, official: 25, probationary: 2 },
  121: { total: 18, official: 17, probationary: 1 },
  122: { total: 14, official: 13, probationary: 1 },
  123: { total: 18, official: 16, probationary: 2 },
  124: { total: 18, official: 18, probationary: 0 },
  125: { total: 22, official: 21, probationary: 1 },
  126: { total: 23, official: 21, probationary: 2 },
  127: { total: 26, official: 23, probationary: 3 },
  128: { total: 31, official: 30, probationary: 1 },
  129: { total: 15, official: 14, probationary: 1 },
  130: { total: 22, official: 21, probationary: 1 },
  131: { total: 16, official: 16, probationary: 0 },
  132: { total: 42, official: 41, probationary: 1 },
  133: { total: 28, official: 27, probationary: 1 },
  134: { total: 17, official: 15, probationary: 2 },
  135: { total: 23, official: 23, probationary: 0 },
  136: { total: 18, official: 15, probationary: 3 },
  137: { total: 19, official: 19, probationary: 0 },
  138: { total: 16, official: 16, probationary: 0 },
  139: { total: 15, official: 15, probationary: 0 },
  140: { total: 14, official: 12, probationary: 2 },
  141: { total: 21, official: 19, probationary: 2 },
  142: { total: 25, official: 24, probationary: 1 },
  143: { total: 13, official: 12, probationary: 1 },
  144: { total: 12, official: 12, probationary: 0 },
  145: { total: 12, official: 12, probationary: 0 },
  146: { total: 18, official: 15, probationary: 3 },
  147: { total: 13, official: 12, probationary: 1 },
  148: { total: 14, official: 14, probationary: 0 },
  149: { total: 10, official: 10, probationary: 0 },
  150: { total: 20, official: 18, probationary: 2 },
  151: { total: 15, official: 14, probationary: 1 },
  152: { total: 17, official: 14, probationary: 3 },
  153: { total: 43, official: 40, probationary: 3 },
  154: { total: 15, official: 13, probationary: 2 },
  155: { total: 27, official: 25, probationary: 2 },
  156: { total: 20, official: 18, probationary: 2 },
  157: { total: 42, official: 40, probationary: 2 },
  158: { total: 39, official: 39, probationary: 0 },
  159: { total: 36, official: 34, probationary: 2 },
  160: { total: 24, official: 22, probationary: 2 },
  161: { total: 15, official: 15, probationary: 0 },
  162: { total: 44, official: 43, probationary: 1 },
  163: { total: 31, official: 29, probationary: 2 },
  164: { total: 15, official: 12, probationary: 3 },
  165: { total: 16, official: 15, probationary: 1 },
  166: { total: 24, official: 23, probationary: 1 },
  167: { total: 24, official: 22, probationary: 2 },
  168: { total: 39, official: 34, probationary: 5 },
  169: { total: 22, official: 21, probationary: 1 },
  170: { total: 5, official: 5, probationary: 0 },
  171: { total: 7, official: 7, probationary: 0 },
  172: { total: 146, official: 144, probationary: 2 },
  173: { total: 25, official: 20, probationary: 5 },
};

async function updateMemberStats() {
  try {
    console.log("📊 Updating party member statistics...\n");

    const snapshot = await db.collection("to_chuc_dang").get();

    if (snapshot.empty) {
      console.log("⚠️  No organizations found");
      process.exit(0);
    }

    console.log(`Found ${snapshot.size} organizations\n`);

    const batch = db.batch();
    let updatedCount = 0;
    let notFoundCount = 0;

    snapshot.forEach((doc) => {
      const data = doc.data();
      const stt = data.stt;

      if (memberStats[stt]) {
        const stats = memberStats[stt];
        batch.update(doc.ref, {
          totalMembers: stats.total,
          officialMembers: stats.official,
          probationaryMembers: stats.probationary,
          updatedAt: new Date(),
        });

        console.log(`✅ [STT ${stt.toString().padStart(3)}] ${data.name}`);
        console.log(
          `   Total: ${stats.total} (Official: ${stats.official}, Probationary: ${stats.probationary})`
        );
        updatedCount++;
      } else {
        console.log(`⚠️  [STT ${stt}] ${data.name} - No stats found`);
        notFoundCount++;
      }
    });

    await batch.commit();

    console.log("\n" + "=".repeat(80));
    console.log("✨ Update completed!");
    console.log("=".repeat(80));
    console.log(`✅ Updated: ${updatedCount} organizations`);
    console.log(`⚠️  No stats found: ${notFoundCount} organizations`);
    console.log("\n🔄 Please restart your Flutter app to see the changes");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

updateMemberStats();
