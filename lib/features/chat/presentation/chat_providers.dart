import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/chat_repository.dart';
import '../data/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

/// Subscribes to one event, then loads its latest 50 messages. Because this
/// is `.autoDispose.family`,
/// leaving the chat screen drops the last watcher, the provider is
/// disposed, and [ref.onDispose] tears down the realtime channel — there
/// is no way to leak a subscription by navigating away.
class ChatController
    extends AutoDisposeFamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String eventId) async {
    final repo = ref.watch(chatRepositoryProvider);
    final pending = <ChatMessage>[];
    var loadingHistory = true;
    final subscription = repo.subscribeToNewMessages(
      eventId: eventId,
      onInsert: (message) {
        if (loadingHistory) pending.add(message);
        _appendMessage(message);
      },
    );
    final client = ref.read(supabaseClientProvider);
    ref.onDispose(() {
      client.removeChannel(subscription.channel);
    });
    await subscription.ready.timeout(
      const Duration(seconds: 10),
      onTimeout: () =>
          throw const AppFailure('Could not connect to team chat.'),
    );
    final initial = await repo.fetchRecentMessages(eventId);
    loadingHistory = false;
    final seen = initial.map((message) => message.id).toSet();
    return [...initial, ...pending.where((message) => seen.add(message.id))];
  }

  void _appendMessage(ChatMessage message) {
    final current = state.valueOrNull;
    if (current == null) return;
    // Guards against ever showing the same message twice, e.g. if a row
    // arrives via realtime just as the initial history query resolves.
    if (current.any((existing) => existing.id == message.id)) return;
    state = AsyncData([...current, message]);
  }

  Future<void> sendMessage({
    required String eventId,
    required String body,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      throw const AppFailure('You must be signed in to send messages.');
    }
    final repo = ref.read(chatRepositoryProvider);
    // No optimistic local append: the message this call inserts comes
    // back through the same realtime INSERT path as everyone else's, so
    // there is a single, authoritative source for what's in the chat.
    await repo.sendMessage(eventId: eventId, userId: userId, body: body);
  }
}

final chatControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatController, List<ChatMessage>, String>(ChatController.new);
