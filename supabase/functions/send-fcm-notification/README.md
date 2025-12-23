# Supabase Edge Function: Send FCM Notification

## Mô tả

Edge Function này tự động gửi FCM (Firebase Cloud Messaging) push notification đến users khi có notification mới được tạo trong Supabase.

## Cách hoạt động

1. **Database Webhook** trigger khi có INSERT vào bảng `notifications`
2. Lấy FCM token từ Firestore (collection `users`)
3. Gửi push notification qua FCM API đến thiết bị của user

## Setup

### 1. Deploy Edge Function

```bash
# Install Supabase CLI (nếu chưa có)
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref aehsrxzaewvoxatzqdca

# Deploy the function
supabase functions deploy send-fcm-notification
```

### 2. Set Environment Variables

Vào Supabase Dashboard → Settings → Edge Functions → Environment Variables:

```
FCM_SERVER_KEY=your-firebase-server-key
FIREBASE_PROJECT_ID=your-firebase-project-id
```

**Lấy FCM Server Key:**

1. Vào Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Settings (⚙️) → Project Settings → Cloud Messaging tab
4. Copy "Server key" (legacy)

**Lấy Project ID:**

- Trong Firebase Console → Project Settings → General → Project ID

### 3. Create Database Webhook

Vào Supabase Dashboard → Database → Webhooks → Create a new hook:

**Settings:**

- **Name:** `send_fcm_on_notification_insert`
- **Table:** `notifications`
- **Events:** `Insert` (✅ checked)
- **Type:** `HTTP Request`
- **Method:** `POST`
- **URL:** `https://aehsrxzaewvoxatzqdca.supabase.co/functions/v1/send-fcm-notification`
- **HTTP Headers:**
  ```
  Content-Type: application/json
  Authorization: Bearer <YOUR_SUPABASE_ANON_KEY>
  ```
- **HTTP Params:** Leave empty

**Anon Key:** Vào Settings → API → Project API keys → `anon` `public`

### 4. Test

Tạo notification mới trong Supabase:

```sql
INSERT INTO notifications (user_id, title, message, type)
VALUES ('Aa07GEX3GbVS8Dc6kOuGaY4Z5x22', 'Test FCM', 'Hello from webhook!', 'info');
```

Hoặc dùng script:

```bash
cd scripts
node test_supabase_notification.js
```

## Monitoring

### Check Function Logs

```bash
supabase functions logs send-fcm-notification
```

Hoặc vào Supabase Dashboard → Edge Functions → send-fcm-notification → Logs

### Check Webhook Logs

Vào Supabase Dashboard → Database → Webhooks → View logs

## Troubleshooting

### ❌ "No FCM token found"

- User chưa login vào app
- FCM token chưa được lưu vào Firestore
- Fix: User cần mở app và login ít nhất 1 lần

### ❌ "Failed to send FCM"

- Kiểm tra `FCM_SERVER_KEY` đúng chưa
- Kiểm tra `FIREBASE_PROJECT_ID` đúng chưa
- FCM token đã expire → User cần login lại

### ❌ "Firestore API error"

- Kiểm tra `FIREBASE_PROJECT_ID` đúng project ID
- Kiểm tra Firestore Rules cho phép read collection `users`

## Architecture

```
Supabase                          Firebase
┌─────────────────┐              ┌──────────────┐
│  notifications  │              │  Firestore   │
│     table       │              │    users     │
└────────┬────────┘              │  collection  │
         │ INSERT                └──────┬───────┘
         │                              │
         ▼                              │ GET fcmToken
┌─────────────────┐                    │
│  DB Webhook     │                    │
│   (trigger)     │                    │
└────────┬────────┘                    │
         │ POST                        │
         ▼                              │
┌─────────────────────────┐           │
│  Edge Function:         │───────────┘
│  send-fcm-notification  │
└────────┬────────────────┘
         │ POST
         ▼
┌─────────────────┐
│   FCM API       │
│  (Google)       │
└────────┬────────┘
         │ Push
         ▼
┌─────────────────┐
│  User Device    │
│  (Android/iOS)  │
└─────────────────┘
```

## Alternative: Use Legacy HTTP API

Nếu không muốn dùng OAuth2, có thể dùng Legacy HTTP API (đơn giản hơn):

Update `index.ts`:

```typescript
// Send using legacy FCM API
const fcmUrl = "https://fcm.googleapis.com/fcm/send";

const response = await fetch(fcmUrl, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `key=${FCM_SERVER_KEY}`,
  },
  body: JSON.stringify({
    to: fcmToken,
    notification: {
      title: title,
      body: body || message,
    },
    data: {
      userId: user_id,
      type: type,
      title: title,
      message: body || message,
    },
    priority: "high",
  }),
});
```

## Security Notes

- ⚠️ **KHÔNG share FCM_SERVER_KEY** publicly
- ✅ Store FCM_SERVER_KEY trong Supabase Environment Variables (encrypted)
- ✅ Dùng RLS (Row Level Security) cho bảng `notifications`
- ✅ Validate webhook payload để tránh spam

## Production Checklist

- [ ] Set `FCM_SERVER_KEY` environment variable
- [ ] Set `FIREBASE_PROJECT_ID` environment variable
- [ ] Create Database Webhook
- [ ] Test với 1 user
- [ ] Test với nhiều users
- [ ] Monitor logs
- [ ] Setup error alerting
