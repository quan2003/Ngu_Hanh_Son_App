-- =====================================================
-- Supabase Storage Policies for feedback-images bucket
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Policy: Allow authenticated users to upload their own images
CREATE POLICY "Allow authenticated users to upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'feedback-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Policy: Allow reading images via signed URLs (public read with signed URL)
CREATE POLICY "Allow reading via signed URLs"
ON storage.objects
FOR SELECT
TO authenticated, anon
USING (
  bucket_id = 'feedback-images'
);

-- 4. Policy: Allow users to delete their own images
CREATE POLICY "Allow users to delete their own images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'feedback-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 5. Policy: Allow users to update their own images
CREATE POLICY "Allow users to update their own images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'feedback-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'feedback-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- Verify policies
-- =====================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage';
