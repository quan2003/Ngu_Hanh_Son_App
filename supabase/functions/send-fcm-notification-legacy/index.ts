/**
 * Supabase Edge Function: Send FCM Notification
 *
 * Uses FCM HTTP v1 API with Service Account JSON authentication.
 * Automatically sends push notifications when new records are inserted into the notifications table.
 *
 * Environment Variables Required:
 * - FIREBASE_SERVICE_ACCOUNT: Full Service Account JSON (contains private_key)
 * - FIREBASE_PROJECT_ID: Firebase project ID (e.g., "nhs-flutter")
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "";
const FIREBASE_PROJECT_ID =
  Deno.env.get("FIREBASE_PROJECT_ID") || "nhs-flutter";

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
    console.log("📬 Webhook received:", JSON.stringify(payload, null, 2));

    if (payload.type !== "INSERT") {
      console.log("⏭️ Not INSERT event, skipping");
      return new Response(JSON.stringify({ message: "Not INSERT, skipped" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { user_id, title, message, body, type } = payload.record;

    if (!user_id || !title) {
      console.log("❌ Missing user_id or title");
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    console.log(`📤 Processing for user: ${user_id}`);

    // Get FCM token from Firestore
    const fcmToken = await getFCMToken(user_id);

    if (!fcmToken) {
      console.log(`⚠️ No FCM token for user: ${user_id}`);
      return new Response(
        JSON.stringify({ message: "No FCM token", userId: user_id }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }
    console.log(`✅ Found token: ${fcmToken.substring(0, 20)}...`);

    // Send FCM notification using HTTP v1 API
    const fcmResponse = await sendFCMNotification(
      fcmToken,
      title,
      body || message,
      {
        userId: user_id,
        type: type || "info",
        notificationId: payload.record.id,
      }
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
    console.error("❌ Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal error", details: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

/**
 * Get FCM token from Firestore using REST API
 */
async function getFCMToken(userId: string): Promise<string | null> {
  try {
    const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${userId}`;

    const response = await fetch(url);

    if (!response.ok) {
      console.error(`Firestore error: ${response.status}`);
      return null;
    }

    const data = await response.json();
    const fcmToken = data.fields?.fcmToken?.stringValue;
    const enabled = data.fields?.notificationsEnabled?.booleanValue;

    if (!fcmToken) {
      console.log(`No fcmToken field in Firestore`);
      return null;
    }

    if (enabled === false) {
      console.log(`Notifications disabled for user`);
      return null;
    }

    return fcmToken;
  } catch (error) {
    console.error("Error fetching FCM token:", error);
    return null;
  }
}

/**
 * Send FCM notification using HTTP v1 API with Service Account authentication
 */
async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  try {
    if (!FIREBASE_SERVICE_ACCOUNT) {
      return {
        success: false,
        error: "FIREBASE_SERVICE_ACCOUNT not configured",
      };
    }

    // Get OAuth2 access token from Service Account
    const accessToken = await getAccessTokenFromServiceAccount();

    if (!accessToken) {
      return { success: false, error: "Failed to get access token" };
    }

    // Use FCM HTTP v1 API
    const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

    const payload = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...data,
          title: title,
          message: body,
          timestamp: new Date().toISOString(),
        },
        android: {
          priority: "high",
          notification: {
            channel_id: "nhs_dangbo_high_importance",
            sound: "default",
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

    const result = await response.json();
    console.log("FCM result:", JSON.stringify(result, null, 2));

    return { success: true };
  } catch (error) {
    console.error("Error sending FCM:", error);
    return { success: false, error: error.message };
  }
}

/**
 * Get OAuth2 access token from Service Account JSON
 */
async function getAccessTokenFromServiceAccount(): Promise<string | null> {
  try {
    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);

    // Create JWT for Google OAuth2
    const now = Math.floor(Date.now() / 1000);
    const expiry = now + 3600; // 1 hour

    const header = {
      alg: "RS256",
      typ: "JWT",
    };

    const claimSet = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: expiry,
      iat: now,
    };

    // Encode JWT
    const encodedHeader = btoa(JSON.stringify(header));
    const encodedClaimSet = btoa(JSON.stringify(claimSet));
    const unsignedToken = `${encodedHeader}.${encodedClaimSet}`;

    // Sign with private key
    const privateKey = serviceAccount.private_key;
    const signature = await signJWT(unsignedToken, privateKey);

    const jwt = `${unsignedToken}.${signature}`;

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
      const error = await tokenResponse.text();
      console.error("Token exchange error:", error);
      return null;
    }

    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
  } catch (error) {
    console.error("Error getting access token:", error);
    return null;
  }
}

/**
 * Sign JWT using RS256 with private key
 */
async function signJWT(data: string, privateKeyPem: string): Promise<string> {
  // Import private key
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKeyPem
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  // Sign data
  const encoder = new TextEncoder();
  const dataBuffer = encoder.encode(data);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    dataBuffer
  );

  // Base64url encode signature
  const base64 = btoa(String.fromCharCode(...new Uint8Array(signature)));
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

console.log("🚀 FCM Notification Function (HTTP v1 API) started");
