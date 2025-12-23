/**
 * Supabase Edge Function: Send FCM Notification (V2 - Simplified)
 *
 * Tự động gửi FCM push notification khi có notification mới trong Supabase
 * Sử dụng Firebase Admin REST API để gửi FCM
 *
 * Trigger: Database Webhook khi INSERT vào bảng notifications
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Firebase configuration from environment variables
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") || "";
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "";

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

    console.log(`📤 Processing notification for user: ${user_id}`);

    // Step 1: Get FCM token from Firestore
    const fcmToken = await getFCMTokenFromFirestore(user_id);

    if (!fcmToken) {
      console.log(`! User has no FCM token: ${user_id}`);
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

    console.log(`✅ Found FCM token: ${fcmToken.substring(0, 20)}...`);

    // Step 2: Send FCM notification
    // IMPORTANT: Keep data fields MINIMAL for background delivery!
    const fcmMessage = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body || message,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: type,
          user_id: user_id,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "nhs_dangbo_high_importance",
            priority: "high",
            sound: "default",
            visibility: "public",
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

    const fcmResponse = await sendFCMUsingHTTPv1(fcmMessage);

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
 * Get FCM token from Firestore using REST API
 */
async function getFCMTokenFromFirestore(
  userId: string
): Promise<string | null> {
  try {
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
    const fcmToken = data.fields?.fcmToken?.stringValue;

    if (!fcmToken) {
      console.log(`⚠️ User ${userId} has no FCM token in Firestore`);
      return null;
    }

    return fcmToken;
  } catch (error) {
    console.error("❌ Error fetching FCM token from Firestore:", error);
    return null;
  }
}

/**
 * Send FCM notification using HTTP v1 API with service account
 */
async function sendFCMUsingHTTPv1(
  message: any
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  try {
    // Get OAuth2 access token from service account
    const accessToken = await getAccessTokenFromServiceAccount();

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
 * Get OAuth2 access token from Firebase service account
 */
async function getAccessTokenFromServiceAccount(): Promise<string | null> {
  try {
    if (!FIREBASE_SERVICE_ACCOUNT) {
      console.error("❌ FIREBASE_SERVICE_ACCOUNT not configured");
      return null;
    }

    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);

    // Create JWT for Google OAuth2
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/cloud-platform",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    };

    // Sign JWT with private key
    const jwt = await signJWT(payload, serviceAccount.private_key);

    // Exchange JWT for access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error(`❌ OAuth2 error: ${tokenResponse.status} ${errorText}`);
      return null;
    }

    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
  } catch (error) {
    console.error("❌ Error getting access token:", error);
    return null;
  }
}

/**
 * Sign JWT using RS256
 */
async function signJWT(payload: any, privateKey: string): Promise<string> {
  const encoder = new TextEncoder();

  // Prepare header
  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const headerBase64 = btoa(JSON.stringify(header))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const payloadBase64 = btoa(JSON.stringify(payload))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const data = `${headerBase64}.${payloadBase64}`;

  // Import private key
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKey.substring(
    pemHeader.length,
    privateKey.length - pemFooter.length
  );
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  // Sign
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(data)
  );

  const signatureBase64 = btoa(
    String.fromCharCode(...new Uint8Array(signature))
  )
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  return `${data}.${signatureBase64}`;
}

console.log("🚀 FCM Notification Edge Function V2 started");
