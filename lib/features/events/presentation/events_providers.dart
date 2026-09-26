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
/// successful join/leave so membership state always comes back from Supabase.
final myMembershipsProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Future.value(<String>{});
  return ref.watch(eventsRepositoryProvider).fetchMyMembershipEventIds(userId);
});

final eventDetailProvider =
    FutureProvider.autoDispose.family<EventModel, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).fetchEvent(eventId);
});

/// UI-only: which event currently has a membership mutation in flight.
final membershipMutationEventIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

class JoinEventController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> join(String eventId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(eventsRepositoryProvider)
          .joinEvent(eventId: eventId, userId: userId),
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

class LeaveEventController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> leave(String eventId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(eventsRepositoryProvider)
          .leaveEvent(eventId: eventId, userId: userId),
    );
    state = result;

    if (!result.hasError) {
      ref.invalidate(myMembershipsProvider);
    }
    return !result.hasError;
  }
}

final leaveEventControllerProvider =
    AsyncNotifierProvider<LeaveEventController, void>(LeaveEventController.new);
