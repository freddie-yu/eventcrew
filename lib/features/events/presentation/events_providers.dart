import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/event_model.dart';
import '../data/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(supabaseClientProvider));
});

final upcomingEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) {
  return ref.watch(eventsRepositoryProvider).fetchUpcomingEvents();
});

/// Event ids the signed-in user currently belongs to. Invalidated after a
/// successful join so "Available" flips to "Confirmed" everywhere it's
/// shown, without any local-only membership flag.
final myMembershipsProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Future.value(<String>{});
  return ref.watch(eventsRepositoryProvider).fetchMyMembershipEventIds(userId);
});

final eventDetailProvider =
    FutureProvider.autoDispose.family<EventModel, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).fetchEvent(eventId);
});

/// UI-only: which event card (if any) currently has a join in flight, so
/// only that card shows a spinner rather than every unjoined card at
/// once. Not server state — purely a presentation concern.
final joiningEventIdProvider = StateProvider.autoDispose<String?>((ref) => null);

class JoinEventController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> join(String eventId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    final repo = ref.read(eventsRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repo.joinEvent(eventId: eventId, userId: userId),
    );
    state = result;

    if (!result.hasError) {
      ref.invalidate(myMembershipsProvider);
    }
    return !result.hasError;
  }
}

final joinEventControllerProvider =
    AsyncNotifierProvider<JoinEventController, void>(JoinEventController.new);
