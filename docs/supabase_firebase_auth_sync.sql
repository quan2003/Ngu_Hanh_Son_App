-- =====================================================
-- OPTION 2: Sync Firebase Auth to Supabase Auth
-- This allows using auth.uid() in RLS policies
-- =====================================================

-- Prerequisites:
-- 1. Enable Supabase Auth in Dashboard
-- 2. Keep your existing policies (fbimg_user_*)
-- 3. Add custom claims to Firebase users

-- Then in your Flutter app, add this function:

/*
// lib/data/services/supabase_auth_sync.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthSync {
  /// Sync Firebase Auth user to Supabase Auth
  static Future<void> syncFirebaseUserToSupabase() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      // Get Firebase ID token
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) return;

      // Sign in to Supabase with Firebase token
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.firebase,
        idToken: idToken,
      );

      print('✅ Synced Firebase user to Supabase Auth');
    } catch (e) {
      print('⚠️ Failed to sync auth: $e');
    }
  }
}

// Call this after Firebase Auth login:
// await SupabaseAuthSync.syncFirebaseUserToSupabase();
*/

-- =====================================================
-- Note: This approach requires more setup
-- Use OPTION 1 (simple anon policies) instead if possible
-- =====================================================
