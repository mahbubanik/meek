/// Supabase Configuration for MEEK App
/// Contains project credentials and initialization

class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase Project URL
  static const String supabaseUrl = 'https://lwqajokojdrktzkptzrt.supabase.co';

  /// Supabase Anon Key (public, safe to include in client apps)
  static const String supabaseAnonKey = 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3cWFqb2tvamRya3R6a3B0enJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMTg2NzgsImV4cCI6MjA4MjU5NDY3OH0.11FWo9rakEW-odDAxn8UnkXkz7mv0e99bvO3T5ZatiY';

  /// Project ID for reference
  static const String projectId = 'lwqajokojdrktzkptzrt';
}
