/**
 * Supabase Edge Function: Send FCM Notification
 *
 * This function sends push notifications via Firebase Cloud Messaging
 * when a new notification is inserted into Supabase database.
 *
 * IMPORTANT: This uses notification-only messages (minimal data field)
 * to ensure notifications display even when app is killed/background.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

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
    fcm_token?: string; // Optional: can be provided directly
  };
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const payload: NotificationPayload = await req.json();
    console.log("📬 Webhook received:", payload.type);

    if (payload.type !== "INSERT") {
      console.log("⏭️  Not INSERT, skipping");
      return new Response(JSON.stringify({ message: "Not INSERT" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
    const { user_id, title, message, body, type, fcm_token } = payload.record;

    if (!user_id || !title) {
      return new Response(JSON.stringify({ error: "Missing fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`📤 Processing for user: ${user_id}`);

    // Get FCM token - either from payload or fetch from Firestore
    let fcmToken = fcm_token;

    if (!fcmToken) {
      console.log("🔍 FCM token not in payload, fetching from Firestore...");
      fcmToken = await getFCMToken(user_id);
    }

    if (!fcmToken) {
      console.log(`⚠️  No FCM token for user: ${user_id}`);
      return new Response(
        JSON.stringify({ message: "No FCM token", userId: user_id }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`✅ Found token: ${fcmToken.substring(0, 20)}...`);

    // Send FCM notification using HTTP v1 API
    // IMPORTANT: notification-only message for background delivery!
    const fcmResponse = await sendFCMNotification(
      fcmToken,
      title,
      body || message,
      type || "info",
      user_id
    );

    if (fcmResponse.success) {
      console.log(`✅ FCM sent to ${user_id}`);
      return new Response(
        JSON.stringify({ message: "FCM sent", userId: user_id }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    } else {
      console.error(`❌ FCM failed: ${fcmResponse.error}`);
      return new Response(
        JSON.stringify({ error: "FCM failed", details: fcmResponse.error }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
    return new Response(
      JSON.stringify({ error: "Internal error", details: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

/**
 * Get FCM token from Supabase users table
 */
async function getFCMToken(userId: string): Promise<string | null> {
  try {
    // Fetch from Supabase (easier than Firestore REST API)
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    if (!supabaseUrl || !supabaseKey) {
      console.error("❌ SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set");
      return null;
    }

    const response = await fetch(
      `${supabaseUrl}/rest/v1/users?id=eq.${userId}&select=fcm_token`,
      {
        headers: {
          apikey: supabaseKey,
          Authorization: `Bearer ${supabaseKey}`,
        },
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error(
        `Supabase users query error: ${response.status} - ${errorText}`
      );
      return null;
    }

    const data = await response.json();

    if (!data || data.length === 0) {
      console.log(`⚠️ No user found in Supabase with id: ${userId}`);
      return null;
    }

    const token = data[0]?.fcm_token || null;

    if (!token) {
      console.log(`⚠️ No fcm_token for user: ${userId}`);
    }

    return token;
  } catch (error) {
    console.error("Error fetching FCM token:", error.message);
    return null;
  }
}

/**
 * Send FCM notification using HTTP v1 API
 * Uses notification-only message (minimal data) for background delivery
 */
async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  type: string,
  userId: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const accessToken = await getAccessToken();

    if (!accessToken) {
      return { success: false, error: "Failed to get access token" };
    }

    const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

    // IMPORTANT: Notification-only message + minimal data for background delivery
    const payload = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: type,
          user_id: userId,
        },
        android: {
          priority: "high",
          notification: {
            channel_id: "nhs_dangbo_high_importance",
            priority: "high",
            sound: "default",
            visibility: "public",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: "default",
              badge: 1,
              category: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        },
      },
    };

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`FCM API error: ${response.status} ${errorText}`);
      return { success: false, error: `${response.status}: ${errorText}` };
    }

    return { success: true };
  } catch (error) {
    console.error("Error sending FCM:", error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Get OAuth2 access token from Firebase service account
 */
async function getAccessToken(): Promise<string | null> {
  try {
    if (!FIREBASE_SERVICE_ACCOUNT) {
      console.error("❌ FIREBASE_SERVICE_ACCOUNT not set");
      return null;
    }

    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    const now = Math.floor(Date.now() / 1000);

    // Create JWT header and payload
    const header = { alg: "RS256", typ: "JWT" };
    const payload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    };

    // Sign JWT
    const jwt = await signJWT(header, payload, serviceAccount.private_key);

    // Exchange JWT for access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error(`OAuth2 error: ${tokenResponse.status} ${errorText}`);
      return null;
    }

    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
  } catch (error) {
    console.error("Error getting access token:", error.message);
    return null;
  }
}

/**
 * Sign JWT using RS256
 */
async function signJWT(
  header: any,
  payload: any,
  privateKey: string
): Promise<string> {
  const encoder = new TextEncoder();

  // Base64URL encode header and payload
  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));
  const data = `${headerB64}.${payloadB64}`;

  // Import private key
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKey
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  // Sign
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(data)
  );

  const signatureB64 = base64UrlEncode(
    String.fromCharCode(...new Uint8Array(signature))
  );

  return `${data}.${signatureB64}`;
}

/**
 * Base64URL encode
 */
function base64UrlEncode(str: string): string {
  const base64 = btoa(str);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

console.log("🚀 FCM Notification Function started");
