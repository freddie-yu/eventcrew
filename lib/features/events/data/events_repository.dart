import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/error_mapper.dart';
import 'event_model.dart';

class EventsRepository {
  EventsRepository(this._client);

  final SupabaseClient _client;

  /// Upcoming events, ordered by start time. "Upcoming" is intentionally
  /// simple for this demo: anything that has not ended yet.
  Future<List<EventModel>> fetchUpcomingEvents() async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('events')
          .select()
          .gte('ends_at', nowIso)
          .order('starts_at');
      return (rows as List)
          .map((row) => EventModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppFailure(
        'Could not load events. Pull to refresh to try again.',
      );
    }
  }

  Future<EventModel> fetchEvent(String eventId) async {
    try {
      final row =
          await _client.from('events').select().eq('id', eventId).single();
      return EventModel.fromMap(row);
    } catch (_) {
      throw const AppFailure('Could not load this event.');
    }
  }

  /// Event ids the current user has joined.
  Future<Set<String>> fetchMyMembershipEventIds(String userId) async {
    try {
      final rows = await _client
          .from('event_members')
          .select('event_id')
          .eq('user_id', userId);
      return (rows as List).map((row) => row['event_id'] as String).toSet();
    } catch (_) {
      throw const AppFailure('Could not load your shifts.');
    }
  }

  /// Joins the current user to an event.
  ///
  /// Duplicate joins are prevented by the `unique(event_id, user_id)`
  /// constraint in the database. The RLS policy also rejects events that
  /// have already ended, so business rules are enforced server-side rather
  /// than trusting a stale client.
  Future<void> joinEvent({
    required String eventId,
    required String userId,
  }) async {
    try {
      await _client.from('event_members').insert({
        'event_id': eventId,
        'user_id': userId,
      });
    } on PostgrestException catch (error) {
      throw mapUniqueViolation(
        error,
        duplicateMessage: "You've already joined this shift.",
        genericMessage: 'Could not join this shift. Please try again.',
      );
    } catch (_) {
      throw const AppFailure('Could not join this shift. Please try again.');
    }
  }

  /// Leaves a shift the current user previously joined.
  ///
  /// The database policy refuses deletion while an active time entry exists,
  /// preventing a worker from disappearing from a shift while still clocked
  /// in even if two clients race or the UI is stale.
  Future<void> leaveEvent({
    required String eventId,
    required String userId,
  }) async {
    try {
      final deleted = await _client
          .from('event_members')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .select('id');

      if ((deleted as List).isEmpty) {
        throw const AppFailure(
          'Could not leave this shift. Clock out first, then try again.',
        );
      }
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        'Could not leave this shift. Clock out first, then try again.',
      );
    }
  }
}
