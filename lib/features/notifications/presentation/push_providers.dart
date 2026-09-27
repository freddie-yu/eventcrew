import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/push_notification_service.dart';

final pushNotificationServiceProvider =
    Provider.autoDispose<PushNotificationService?>((ref) {
  if (!Env.isFirebaseConfigured) return null;

  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final service = PushNotificationService(
    ref.watch(supabaseClientProvider),
    FirebaseMessaging.instance,
  );
  ref.onDispose(service.dispose);
  return service;
});

class PushRegistrationController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final user = ref.watch(currentUserProvider);
    final service = ref.watch(pushNotificationServiceProvider);
    if (user == null || service == null) return false;
    return service.isRegistered(user.id);
  }

  Future<bool> enable() async {
    final user = ref.read(currentUserProvider);
    final service = ref.read(pushNotificationServiceProvider);
    if (user == null || service == null) return false;

    state = const AsyncLoading();
    try {
      final enabled = await service.enableForUser(user.id);
      state = AsyncData(enabled);
      return enabled;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final pushRegistrationControllerProvider =
    AsyncNotifierProvider.autoDispose<PushRegistrationController, bool>(
  PushRegistrationController.new,
);

final foregroundPushMessageProvider =
    StreamProvider.autoDispose<RemoteMessage>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  if (service == null) return const Stream<RemoteMessage>.empty();
  return service.foregroundMessages;
});
