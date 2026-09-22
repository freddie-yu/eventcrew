import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/chat_repository.dart';
import '../data/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

/// Loads the latest-50 message history for one event, then appends
/// realtime INSERTs as they arrive. Because this is `.autoDispose.family`,
/// leaving the chat screen drops the last watcher, the provider is
/// disposed, and [ref.onDispose] tears down the realtime channel — there
/// is no way to leak a subscription by navigating away.
class ChatController extends AutoDisposeFamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String eventId) async {
    final repo = ref.watch(chatRepositoryProvider);
    final initial = await repo.fetchRecentMessages(eventId);

    final channel = repo.subscribeToNewMessages(
      eventId: eventId,
      onInsert: _appendMessage,
    );

    ref.onDispose(() {
      ref.read(supabaseClientProvider).removeChannel(channel);
    });

    return initial;
  }

  void _appendMessage(ChatMessage message) {
    final current = state.valueOrNull;
    if (current == null) return;
    // Guards against ever showing the same message twice, e.g. if a row
    // arrives via realtime just as the initial history query resolves.
    if (current.any((existing) => existing.id == message.id)) return;
    state = AsyncData([...current, message]);
  }

  Future<void> sendMessage({required String eventId, required String body}) async {
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
