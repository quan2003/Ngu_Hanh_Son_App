-- =====================================================
-- SUPABASE NOTIFICATIONS SETUP
-- =====================================================
-- File này setup bảng notifications trong Supabase
-- để thay thế Firebase Cloud Firestore
-- =====================================================

-- 1. Tạo bảng notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  body TEXT, -- Alias cho message (để tương thích với Firebase)
  type TEXT DEFAULT 'info', -- info, warning, success, error, announcement
  created_at TIMESTAMPTZ DEFAULT NOW(),
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  action_url TEXT,
  metadata JSONB,
  data JSONB -- Alias cho metadata (để tương thích với Firebase)
);

-- 2. Tạo indexes để tăng hiệu suất query
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, read);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policies (nếu có)
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Allow public read for notifications" ON notifications;
DROP POLICY IF EXISTS "Allow public insert for notifications" ON notifications;
DROP POLICY IF EXISTS "Allow public update for notifications" ON notifications;
DROP POLICY IF EXISTS "Allow public delete for notifications" ON notifications;

-- 5. Tạo policies - ALLOW ALL (vì dùng anon key)
-- Policy cho SELECT
CREATE POLICY "Allow public read for notifications"
ON notifications FOR SELECT
TO anon, authenticated
USING (true);

-- Policy cho INSERT
CREATE POLICY "Allow public insert for notifications"
ON notifications FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Policy cho UPDATE
CREATE POLICY "Allow public update for notifications"
ON notifications FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- Policy cho DELETE
CREATE POLICY "Allow public delete for notifications"
ON notifications FOR DELETE
TO anon, authenticated
USING (true);

-- 6. Tạo function để auto-update read_at khi read = true
CREATE OR REPLACE FUNCTION update_notification_read_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.read = TRUE AND OLD.read = FALSE THEN
    NEW.read_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Tạo trigger
DROP TRIGGER IF EXISTS trigger_update_notification_read_at ON notifications;
CREATE TRIGGER trigger_update_notification_read_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_read_at();

-- 8. Tạo function để cleanup old notifications (> 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notifications 
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- 9. Comment để giải thích
COMMENT ON TABLE notifications IS 'Bảng lưu thông báo cho users - thay thế Firebase Firestore';
COMMENT ON COLUMN notifications.user_id IS 'Firebase User UID';
COMMENT ON COLUMN notifications.type IS 'Loại thông báo: info, warning, success, error, announcement';
COMMENT ON COLUMN notifications.metadata IS 'Dữ liệu bổ sung dạng JSON';

-- =====================================================
-- DONE! 
-- =====================================================
-- Copy toàn bộ SQL trên và chạy trong Supabase SQL Editor
-- 1. Vào Supabase Dashboard
-- 2. Click "SQL Editor" (bên trái)
-- 3. Click "New Query"
-- 4. Paste toàn bộ SQL này vào
-- 5. Click "Run" hoặc F5
-- 6. Kiểm tra "Table Editor" để xem bảng notifications
-- =====================================================
