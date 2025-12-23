-- =====================================================
-- Supabase Storage Policies for feedback-images bucket
-- SIMPLE VERSION - Allow upload with anon key
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. DROP existing policies if they exist (run these first to clean up)
DROP POLICY IF EXISTS "Allow authenticated users to upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow reading via signed URLs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own images" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon to upload to feedback-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon to read from feedback-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon to delete from feedback-images" ON storage.objects;

-- 3. Policy: Allow anon users to upload to feedback-images bucket
CREATE POLICY "Allow anon to upload to feedback-images"
ON storage.objects
FOR INSERT
TO anon, authenticated
WITH CHECK (
  bucket_id = 'feedback-images'
);

-- 4. Policy: Allow anyone to read from feedback-images (for signed URLs)
CREATE POLICY "Allow anon to read from feedback-images"
ON storage.objects
FOR SELECT
TO anon, authenticated
USING (
  bucket_id = 'feedback-images'
);

-- 5. Policy: Allow anon users to delete from feedback-images bucket
CREATE POLICY "Allow anon to delete from feedback-images"
ON storage.objects
FOR DELETE
TO anon, authenticated
USING (
  bucket_id = 'feedback-images'
);

-- =====================================================
-- Verify policies are created
-- =====================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

-- =====================================================
-- Expected output: You should see 3 policies
-- 1. Allow anon to upload to feedback-images
-- 2. Allow anon to read from feedback-images  
-- 3. Allow anon to delete from feedback-images
-- =====================================================
