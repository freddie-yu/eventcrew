/// A user-safe error surfaced by a repository.
///
/// Repositories catch the underlying Supabase/Postgrest/Auth exception and
/// throw an [AppFailure] with a short, friendly message instead — the UI
/// layer never sees raw exception text or Postgres error codes.
class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
