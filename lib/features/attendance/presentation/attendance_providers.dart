import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/attendance_repository.dart';
import '../data/time_entry_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(supabaseClientProvider));
});

/// Active time entry for the given event, scoped to the signed-in user.
/// Invalidated (never patched optimistically) after clock in/out so the
/// UI always reflects what the server has.
final activeTimeEntryProvider =
    FutureProvider.autoDispose.family<TimeEntry?, String>((ref, eventId) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Future.value(null);
  return ref.watch(attendanceRepositoryProvider).fetchActiveEntry(
        eventId: eventId,
        userId: userId,
      );
});

class AttendanceController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> clockIn(String eventId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    final repo = ref.read(attendanceRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repo.clockIn(eventId: eventId, userId: userId),
    );
    state = result;
    if (!result.hasError) {
      ref.invalidate(activeTimeEntryProvider(eventId));
    }
    return !result.hasError;
  }

  Future<bool> clockOut({required String eventId, required String entryId}) async {
    state = const AsyncLoading();
    final repo = ref.read(attendanceRepositoryProvider);
    final result = await AsyncValue.guard(() => repo.clockOut(entryId: entryId));
    state = result;
    if (!result.hasError) {
      ref.invalidate(activeTimeEntryProvider(eventId));
    }
    return !result.hasError;
  }
}

final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, void>(AttendanceController.new);
