// Template for lib/core/constants/supabase_keys.dart (gitignored).
// Copy this file to supabase_keys.dart and fill in your project's real
// values from the Supabase Dashboard -> Project Settings -> API.
//
// The anon/publishable key is safe to ship in a Flutter app by design.
// Never put a service_role key anywhere in lib/ — service_role belongs
// only in Edge Functions, never in client code.
class SupabaseKeys {
  SupabaseKeys._();

  static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_PUBLISHABLE_KEY';
}
