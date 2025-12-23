class SupabaseConfig {
  // Supabase project credentials
  // Get these from: https://app.supabase.com/project/_/settings/api

  static const String supabaseUrl = 'https://aehsrxzaewvoxatzqdca.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaHNyeHphZXd2b3hhdHpxZGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMzczNTIsImV4cCI6MjA3NzYxMzM1Mn0.oRtIqcoqcRH3RsFpTO5Ze0ZEgt2LThO3dTPwJ3X9k0g';

  // Bucket name for feedback images
  static const String feedbackImagesBucket = 'feedback-images';

  // Instructions:
  // 1. Go to https://supabase.com and create a free account
  // 2. Create a new project
  // 3. Go to Settings > API to get your URL and anon key
  // 4. Go to Storage and create a new bucket called 'feedback-images'
  // 5. Set bucket to PRIVATE (we'll use signed URLs)
  // 6. Add the following RLS policy to allow authenticated uploads:
  //    - Policy name: "Allow authenticated users to upload"
  //    - Allowed operation: INSERT
  //    - Target roles: authenticated
  //    - USING expression: auth.uid()::text = (storage.foldername(name))[1]
  //    - WITH CHECK expression: auth.uid()::text = (storage.foldername(name))[1]
  // 7. Add policy to allow users to read their own images:
  //    - Policy name: "Allow users to read their own images"
  //    - Allowed operation: SELECT
  //    - Target roles: authenticated, anon
  //    - USING expression: true (we use signed URLs, so this is safe)
}
