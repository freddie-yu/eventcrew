import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_failure.dart';

/// Postgres error code for a unique-constraint violation.
///
/// Both "join an event twice" (event_members) and "clock in twice"
/// (the partial unique index on time_entries) are enforced at the
/// database level and surface as this code — see
/// supabase/migrations/001_initial_schema.sql.
const String kUniqueViolationCode = '23505';

/// Maps a caught error to a friendly [AppFailure].
///
/// If [error] is a [PostgrestException] carrying [kUniqueViolationCode],
/// the caller-supplied [duplicateMessage] is used; otherwise
/// [genericMessage] is used. This keeps the "was it a duplicate row"
/// mapping in one pure, unit-testable place rather than duplicated
/// per-repository.
AppFailure mapUniqueViolation(
  Object error, {
  required String duplicateMessage,
  required String genericMessage,
}) {
  if (error is PostgrestException && error.code == kUniqueViolationCode) {
    return AppFailure(duplicateMessage);
  }
  return AppFailure(genericMessage);
}
