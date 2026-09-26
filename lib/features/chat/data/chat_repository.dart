import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import 'message_model.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;
  final Map<String, Map<String, dynamic>> _profileCache = {};

  static const int historyLimit = 50;

  Future<List<ChatMessage>> fetchRecentMessages(String eventId) async {
    try {
      final rows = await _client
          .from('messages')
          .select(
            'id,event_id,user_id,body,created_at,'
            'profiles!messages_user_id_fkey(full_name,avatar_url,role)',
          )
          .eq('event_id', eventId)
          .order('created_at', ascending: false)
          .limit(historyLimit);

      final messages = (rows as List)
          .map((row) {
            final map = row as Map<String, dynamic>;
            final profile = map['profiles'];
            if (profile is Map) {
              _profileCache[map['user_id'] as String] =
                  Map<String, dynamic>.from(profile);
            }
            return ChatMessage.fromMap(map);
          })
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

  Future<ChatMessage> _hydrateRealtimeMessage(
    Map<String, dynamic> row,
  ) async {
    final userId = row['user_id'] as String;
    var profile = _profileCache[userId];

    if (profile == null) {
      final fetched = await _client
          .from('profiles')
          .select('full_name,avatar_url,role')
          .eq('id', userId)
          .single();
      profile = Map<String, dynamic>.from(fetched);
      _profileCache[userId] = profile;
    }

    return ChatMessage.fromMap({...row, 'profiles': profile});
  }

  ({RealtimeChannel channel, Future<void> ready}) subscribeToNewMessages({
    required String eventId,
    required void Function(ChatMessage message) onInsert,
  }) {
    final channel = _client.channel('messages:event:$eventId');
    final ready = Completer<void>();
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'event_id',
        value: eventId,
      ),
      callback: (payload) {
        unawaited(
          _hydrateRealtimeMessage(payload.newRecord)
              .then(onInsert)
              .catchError((Object _, StackTrace __) {}),
        );
      },
    );
    channel.subscribe((status, error) {
      if (ready.isCompleted) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        ready.complete();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        ready.completeError(
          const AppFailure('Could not connect to team chat.'),
        );
      }
    });
    return (channel: channel, ready: ready.future);
  }
}
