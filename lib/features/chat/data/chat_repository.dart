import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import 'message_model.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  static const int historyLimit = 50;

  /// The latest [historyLimit] messages for the event, returned oldest
  /// first so they can be rendered directly top-to-bottom.
  Future<List<ChatMessage>> fetchRecentMessages(String eventId) async {
    try {
      final rows = await _client
          .from('messages')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false)
          .limit(historyLimit);
      final messages = (rows as List)
          .map((row) => ChatMessage.fromMap(row as Map<String, dynamic>))
          .toList();
      return messages.reversed.toList();
    } catch (_) {
      throw const AppFailure('Could not load chat history.');
    }
  }

  Future<void> sendMessage({
    required String eventId,
    required String userId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    try {
      await _client.from('messages').insert({
        'event_id': eventId,
        'user_id': userId,
        'body': trimmed,
      });
    } catch (_) {
      throw const AppFailure('Message could not be sent. Please try again.');
    }
  }

  /// Opens a realtime channel scoped to `event_id = eventId`, invoking
  /// [onInsert] for each newly inserted message. Callers own the returned
  /// channel and must close it (via `SupabaseClient.removeChannel`) when
  /// finished, so no global "all events" subscription is ever left open.
  RealtimeChannel subscribeToNewMessages({
    required String eventId,
    required void Function(ChatMessage message) onInsert,
  }) {
    final channel = _client.channel('messages:event:$eventId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'event_id',
        value: eventId,
      ),
      callback: (payload) => onInsert(ChatMessage.fromMap(payload.newRecord)),
    );
    channel.subscribe();
    return channel;
  }
}
