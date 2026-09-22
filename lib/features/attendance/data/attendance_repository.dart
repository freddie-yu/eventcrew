import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/error_mapper.dart';
import 'time_entry_model.dart';

class AttendanceRepository {
  AttendanceRepository(this._client);

  final SupabaseClient _client;

  /// The current active (not clocked-out) entry for this user/event, if
  /// any. Always re-fetched from Supabase — never derived from local
  /// state — so attendance survives navigation and reload.
  Future<TimeEntry?> fetchActiveEntry({
    required String eventId,
    required String userId,
  }) async {
    try {
      final row = await _client
          .from('time_entries')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .isFilter('clock_out', null)
          .maybeSingle();
      return row == null ? null : TimeEntry.fromMap(row);
    } catch (_) {
      throw const AppFailure('Could not load attendance status.');
    }
  }

  /// Creates a new active time entry. The database's partial unique index
  /// (`one_active_time_entry_per_user_event`) is what actually prevents a
  /// second concurrent clock-in — this just maps that violation to a
  /// friendly message.
  Future<void> clockIn({required String eventId, required String userId}) async {
    try {
      await _client.from('time_entries').insert({
        'event_id': eventId,
        'user_id': userId,
      });
    } on PostgrestException catch (error) {
      throw mapUniqueViolation(
        error,
        duplicateMessage: "You're already clocked in for this shift.",
        genericMessage: 'Could not clock in. Please try again.',
      );
    } catch (_) {
      throw const AppFailure('Could not clock in. Please try again.');
    }
  }

  /// Closes the active entry by setting `clock_out`. Scoped to
  /// `clock_out IS NULL` so this only ever affects the currently active
  /// row, even if called twice in a race.
  Future<void> clockOut({required String entryId}) async {
    try {
      await _client
          .from('time_entries')
          .update({'clock_out': DateTime.now().toUtc().toIso8601String()})
          .eq('id', entryId)
          .isFilter('clock_out', null);
    } catch (_) {
      throw const AppFailure('Could not clock out. Please try again.');
    }
  }
}
