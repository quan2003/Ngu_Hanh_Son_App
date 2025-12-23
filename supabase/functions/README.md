# Supabase Edge Functions

## Active Functions

### send-fcm-notification-legacy

**Purpose:** Automatically sends FCM push notifications when new records are inserted into the `notifications` table.

**Technology:**

- FCM HTTP v1 API
- Service Account authentication (OAuth2)
- Firestore for FCM token storage

**Trigger:** Database Webhook on `notifications` table INSERT

**Environment Variables:**

- `FIREBASE_SERVICE_ACCOUNT`: Full Service Account JSON (contains private_key)
- `FIREBASE_PROJECT_ID`: Firebase project ID (e.g., "nhs-flutter")

**Files:**

```
send-fcm-notification-legacy/
└── index.ts          # Main function code
```

**Deployment:**

```powershell
supabase functions deploy send-fcm-notification-legacy
```

**Logs:**

```powershell
supabase functions logs send-fcm-notification-legacy --follow
```

**Documentation:** See [FCM_SETUP_GUIDE_v2.md](../../docs/FCM_SETUP_GUIDE_v2.md)

---

## Deployment Commands

```powershell
# Login to Supabase
supabase login

# Link project
supabase link --project-ref aehsrxzaewvoxatzqdca

# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy send-fcm-notification-legacy

# View logs
supabase functions logs send-fcm-notification-legacy --follow
```

## Setting Secrets

```powershell
# Set Service Account JSON
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content .\firebase-admin-key.json -Raw)"

# Set Project ID
supabase secrets set FIREBASE_PROJECT_ID="nhs-flutter"

# List all secrets
supabase secrets list

# Delete a secret
supabase secrets unset SECRET_NAME
```

## Testing Locally

```powershell
# Serve function locally
supabase functions serve send-fcm-notification-legacy

# Test with curl
curl -X POST http://localhost:54321/functions/v1/send-fcm-notification-legacy `
  -H "Content-Type: application/json" `
  -d '{
    "type": "INSERT",
    "record": {
      "id": "test-id",
      "user_id": "Aa07GEX3GbVS8Dc6kOuGaY4Z5x22",
      "title": "Local Test",
      "message": "Testing locally",
      "type": "info"
    }
  }'
```

## Best Practices

1. **Never commit secrets** - Use Supabase Secrets for sensitive data
2. **Test locally first** - Use `supabase functions serve` before deploying
3. **Monitor logs** - Check function logs after deployment
4. **Use TypeScript** - Better type safety and error detection
5. **Handle errors gracefully** - Return appropriate HTTP status codes
6. **Log important events** - Use `console.log()` for debugging

## Troubleshooting

### Function not receiving requests

- Check webhook configuration in Supabase Dashboard
- Verify Authorization header has correct Anon Key
- Check function deployment status

### Function errors

- Check logs: `supabase functions logs send-fcm-notification-legacy`
- Verify environment variables are set
- Test function locally with mock data

### Secrets not working

- Re-deploy function after setting secrets
- Verify secrets are set: `supabase secrets list`
- Check secret names match exactly in code

---

**Current Deployment:** `send-fcm-notification-legacy` is deployed and active.
