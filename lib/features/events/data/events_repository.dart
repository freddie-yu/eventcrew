import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import 'event_model.dart';

class EventsRepository {
  EventsRepository(this._client);

  final SupabaseClient _client;

  Future<List<EventModel>> fetchUpcomingEvents() async {
    try {
      final rows = await _client.rpc('list_upcoming_events');
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
      final eventRow =
          await _client.from('events').select().eq('id', eventId).single();
      final staffingRows = await _client.rpc(
        'get_event_staffing',
        params: {'p_event_id': eventId},
      );
      final staffing = (staffingRows as List).cast<Map<String, dynamic>>();
      final summary =
          staffing.isEmpty ? const <String, dynamic>{} : staffing.first;
      return EventModel.fromMap({...eventRow, ...summary});
    } catch (_) {
      throw const AppFailure('Could not load this event.');
    }
  }

  Future<Map<String, MembershipStatus>> fetchMyMemberships(
    String userId,
  ) async {
    try {
      final rows = await _client
          .from('event_members')
          .select('event_id,status')
          .eq('user_id', userId);
      return {
        for (final row in rows as List)
          row['event_id'] as String:
              MembershipStatus.fromDatabase(row['status'] as String),
      };
    } catch (_) {
      throw const AppFailure('Could not load your shifts.');
    }
  }

  Future<MembershipStatus> joinEvent({required String eventId}) async {
    try {
      final status = await _client.rpc(
        'join_event',
        params: {'p_event_id': eventId},
      );
      return MembershipStatus.fromDatabase(status as String);
    } catch (_) {
      throw const AppFailure('Could not join this shift. Please try again.');
    }
  }

  Future<void> leaveEvent({required String eventId}) async {
    try {
      await _client.rpc(
        'leave_event',
        params: {'p_event_id': eventId},
      );
    } catch (_) {
      throw const AppFailure(
        'Could not leave this shift. Clock out first, then try again.',
      );
    }
  }
}
