-- =====================================================
-- CREATE DATABASE WEBHOOK FOR FCM NOTIFICATIONS
-- =====================================================
-- Script này tạo Database Webhook để tự động gửi FCM
-- khi có notification mới INSERT vào bảng notifications
-- =====================================================

-- Note: Database Webhooks trong Supabase không thể tạo qua SQL
-- Phải tạo qua Dashboard hoặc Management API

-- Tuy nhiên, bạn có thể dùng PostgreSQL Trigger + pg_net extension
-- để gọi Edge Function trực tiếp từ database

-- =====================================================
-- OPTION 1: Sử dụng Supabase Webhook (RECOMMENDED)
-- =====================================================
-- Cấu hình qua Dashboard:
-- 1. Vào: https://supabase.com/dashboard/project/aehsrxzaewvoxatzqdca/database/hooks
-- 2. Click "Create a new hook"
-- 3. Settings:
--    Name:     send_fcm_on_notification_insert
--    Table:    notifications
--    Events:   Insert (checked)
--    Type:     HTTP Request
--    Method:   POST
--    URL:      https://aehsrxzaewvoxatzqdca.supabase.co/functions/v1/send-fcm-notification-legacy
--    Headers:  
--      Content-Type: application/json
--      Authorization: Bearer <YOUR_SUPABASE_ANON_KEY>

-- =====================================================
-- OPTION 2: PostgreSQL Trigger với pg_net (ADVANCED)
-- =====================================================
-- Sử dụng pg_net extension để gọi HTTP request từ trigger

-- 1. Enable pg_net extension (nếu chưa có)
-- Note: pg_net có thể chưa available trên tất cả Supabase projects
-- CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create function to call Edge Function via pg_net
CREATE OR REPLACE FUNCTION notify_fcm_on_insert()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  anon_key TEXT;
  payload JSONB;
BEGIN
  -- Configuration
  webhook_url := 'https://aehsrxzaewvoxatzqdca.supabase.co/functions/v1/send-fcm-notification-legacy';
  anon_key := 'YOUR_SUPABASE_ANON_KEY'; -- REPLACE THIS!
  
  -- Build payload matching Supabase webhook format
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'notifications',
    'schema', 'public',
    'record', row_to_json(NEW),
    'old_record', NULL
  );
  
  -- Call Edge Function using pg_net (if available)
  -- Uncomment if pg_net is enabled:
  /*
  PERFORM net.http_post(
    url := webhook_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || anon_key
    ),
    body := payload
  );
  */
  
  -- Log for debugging
  RAISE NOTICE 'FCM notification trigger fired for user: %', NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger
-- Note: Đang comment out vì cần enable pg_net trước
/*
DROP TRIGGER IF EXISTS trigger_notify_fcm ON notifications;
CREATE TRIGGER trigger_notify_fcm
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_fcm_on_insert();
*/

-- =====================================================
-- OPTION 3: Supabase Management API (Script)
-- =====================================================
-- Bạn có thể dùng Management API để tạo webhook bằng script
-- Xem file: create-webhook-via-api.js

-- =====================================================
-- TESTING
-- =====================================================
-- Test webhook bằng cách tạo notification mới:

-- Test 1: Notification đơn giản
INSERT INTO notifications (user_id, title, message, type)
VALUES ('Aa07GEX3GbVS8Dc6kOuGaY4Z5x22', '🧪 Test FCM Webhook', 'This should trigger FCM!', 'info');

-- Test 2: Notification với metadata
INSERT INTO notifications (user_id, title, message, type, metadata)
VALUES (
  'Aa07GEX3GbVS8Dc6kOuGaY4Z5x22',
  '🎉 Test với metadata',
  'Notification có metadata',
  'success',
  '{"source": "sql_test", "priority": "high"}'::jsonb
);

-- Check logs trong Supabase Dashboard:
-- Edge Functions → send-fcm-notification-legacy → Logs

-- =====================================================
-- MONITORING
-- =====================================================
-- View recent notifications
SELECT 
  id,
  user_id,
  title,
  message,
  type,
  created_at,
  read
FROM notifications
ORDER BY created_at DESC
LIMIT 10;

-- Count unread notifications per user
SELECT 
  user_id,
  COUNT(*) as unread_count
FROM notifications
WHERE read = false
GROUP BY user_id
ORDER BY unread_count DESC;

-- =====================================================
-- CLEANUP (if needed)
-- =====================================================
-- Delete test notifications
-- DELETE FROM notifications 
-- WHERE title LIKE '%Test%' OR title LIKE '%test%';

-- Drop trigger (if using Option 2)
-- DROP TRIGGER IF EXISTS trigger_notify_fcm ON notifications;
-- DROP FUNCTION IF EXISTS notify_fcm_on_insert();

-- =====================================================
-- NOTES
-- =====================================================
-- 1. RECOMMEND: Use Option 1 (Supabase Dashboard Webhook)
--    - Easiest to setup
--    - Best for most use cases
--    - Managed by Supabase
--
-- 2. Option 2 (pg_net trigger) requires pg_net extension
--    - More complex
--    - May not be available on all plans
--    - Requires ANON_KEY hardcoded (security concern)
--
-- 3. For production:
--    - Monitor webhook logs regularly
--    - Set up error alerting
--    - Consider rate limiting
--    - Handle FCM token expiration

COMMENT ON FUNCTION notify_fcm_on_insert() IS 
'Function to trigger FCM notification via Edge Function when notification is inserted';
