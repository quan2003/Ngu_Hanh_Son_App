/**
 * Supabase Edge Function: Send FCM Notification
 *
 * Tự động gửi FCM push notification khi có notification mới trong Supabase
 *
 * Trigger: Database Webhook khi INSERT vào bảng notifications
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// FCM Server Key - REPLACE THIS with your Firebase Cloud Messaging Server Key
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") || "";
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") || "";

interface NotificationPayload {
  type: string;
  record: {
    id: string;
    user_id: string;
    title: string;
    message: string;
    body?: string;
    type: string;
    created_at: string;
    read: boolean;
  };
}

interface FirestoreUser {
  fcmToken?: string;
  notificationsEnabled?: boolean;
}

serve(async (req) => {
  try {
    // Only allow POST
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Parse webhook payload
    const payload: NotificationPayload = await req.json();
    console.log("📬 Received notification webhook:", payload);

    // Validate payload
    if (payload.type !== "INSERT") {
      console.log("⚠️ Not an INSERT event, skipping");
      return new Response(JSON.stringify({ message: "Not an INSERT event" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { record } = payload;
    const { user_id, title, message, body, type } = record;

    if (!user_id || !title || (!message && !body)) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    console.log(`📤 Processing notification for user: ${user_id}`);    // Step 1: Get FCM token from Firestore
    const fcmToken = await getFCMTokenFromFirestore(user_id);

    if (!fcmToken) {
      console.log(`! User has no FCM token: ${user_id}`);
      console.log('💡 User needs to:');
      console.log('   1. Open the app');
      console.log('   2. Login or complete email verification');
      console.log('   3. FCM token will be saved automatically');
      return new Response(
        JSON.stringify({
          error: "User has no FCM token",
          message: "User needs to login to the app to receive notifications",
          userId: user_id,
          success: false,
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    console.log(`✅ Found FCM token: ${fcmToken.substring(0, 20)}...`);    // Step 2: Send FCM notification
    // IMPORTANT: Keep data fields MINIMAL for background delivery!
    // Too many data fields can prevent notification from showing when app is killed
    const fcmMessage = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body || message,
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: type,
          user_id: user_id,
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "nhs_dangbo_high_importance",
            priority: "high" as const,
            sound: "default",
            visibility: "public" as const,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body || message,
              },
              sound: "default",
              badge: 1,
              category: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        },
      },
    };

    const fcmResponse = await sendFCM(fcmMessage);

    if (fcmResponse.success) {
      console.log(`✅ FCM notification sent successfully to ${user_id}`);
      return new Response(
        JSON.stringify({
          message: "FCM notification sent",
          userId: user_id,
          messageId: fcmResponse.messageId,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    } else {
      console.error(`❌ Failed to send FCM: ${fcmResponse.error}`);
      return new Response(
        JSON.stringify({
          error: "Failed to send FCM",
          details: fcmResponse.error,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
  } catch (error) {
    console.error("❌ Error processing notification:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});

/**
 * Get FCM token from Firestore
 */
async function getFCMTokenFromFirestore(
  userId: string
): Promise<string | null> {
  try {
    // Use Firestore REST API
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${userId}`;

    const response = await fetch(firestoreUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      console.error(
        `❌ Firestore API error: ${response.status} ${response.statusText}`
      );
      return null;
    }

    const data = await response.json();

    // Extract fcmToken from Firestore document
    const fcmToken = data.fields?.fcmToken?.stringValue;
    const notificationsEnabled =
      data.fields?.notificationsEnabled?.booleanValue;

    if (!fcmToken) {
      console.log(`⚠️ User ${userId} has no FCM token in Firestore`);
      return null;
    }

    if (notificationsEnabled === false) {
      console.log(`⚠️ User ${userId} has disabled notifications`);
      return null;
    }

    return fcmToken;
  } catch (error) {
    console.error("❌ Error fetching FCM token from Firestore:", error);
    return null;
  }
}

/**
 * Send FCM notification using FCM v1 API
 */
async function sendFCM(
  message: any
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  try {
    // Get OAuth2 access token for FCM
    const accessToken = await getAccessToken();

    if (!accessToken) {
      return { success: false, error: "Failed to get access token" };
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ FCM API error: ${response.status} ${errorText}`);
      return { success: false, error: `${response.status}: ${errorText}` };
    }

    const result = await response.json();
    return { success: true, messageId: result.name };
  } catch (error) {
    console.error("❌ Error sending FCM:", error);
    return { success: false, error: error.message };
  }
}

/**
 * Get OAuth2 access token for FCM
 * Note: For production, use service account key or workload identity
 */
async function getAccessToken(): Promise<string | null> {
  try {
    // For now, we'll use the legacy Server Key
    // TODO: Migrate to OAuth2 with service account

    // For FCM HTTP v1, we need OAuth2 token
    // This is a simplified version - in production, use proper OAuth2 flow

    // If using Server Key (legacy), return it directly
    if (FCM_SERVER_KEY) {
      return FCM_SERVER_KEY;
    }

    console.error("❌ No FCM credentials configured");
    return null;
  } catch (error) {
    console.error("❌ Error getting access token:", error);
    return null;
  }
}

console.log("🚀 FCM Notification Edge Function started");
