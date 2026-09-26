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

final myMembershipsProvider =
    FutureProvider.autoDispose<Map<String, MembershipStatus>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return Future.value(const <String, MembershipStatus>{});
  }
  return ref.watch(eventsRepositoryProvider).fetchMyMemberships(userId);
});

final eventDetailProvider =
    FutureProvider.autoDispose.family<EventModel, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).fetchEvent(eventId);
});

final membershipMutationEventIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

class JoinEventController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<MembershipStatus?> join(String eventId) async {
    if (ref.read(currentUserProvider) == null) return null;

    state = const AsyncLoading();
    try {
      final status =
          await ref.read(eventsRepositoryProvider).joinEvent(eventId: eventId);
      state = const AsyncData(null);
      ref.invalidate(myMembershipsProvider);
      ref.invalidate(upcomingEventsProvider);
      ref.invalidate(eventDetailProvider(eventId));
      return status;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final joinEventControllerProvider =
    AsyncNotifierProvider<JoinEventController, void>(JoinEventController.new);

class LeaveEventController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> leave(String eventId) async {
    if (ref.read(currentUserProvider) == null) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(eventsRepositoryProvider).leaveEvent(eventId: eventId),
    );
    state = result;

    if (!result.hasError) {
      ref.invalidate(myMembershipsProvider);
      ref.invalidate(upcomingEventsProvider);
      ref.invalidate(eventDetailProvider(eventId));
    }
    return !result.hasError;
  }
}

final leaveEventControllerProvider =
    AsyncNotifierProvider<LeaveEventController, void>(LeaveEventController.new);
