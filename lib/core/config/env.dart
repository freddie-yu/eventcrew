/// Compile-time Supabase configuration.
///
/// Values are read via `String.fromEnvironment`, which only sees values
/// supplied at build/run time through `--dart-define` (or
/// `--dart-define-from-file`). Nothing here is a secret checked into the
/// repo — the anon key is safe to ship to clients by design, because
/// Postgres Row Level Security (not this key) is what actually protects
/// data. See supabase/migrations/001_initial_schema.sql.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True only when both compile-time values were actually supplied. The
  /// app must never silently run against empty/placeholder credentials.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
