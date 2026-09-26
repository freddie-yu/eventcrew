import 'dart:async';

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

  unawaited(service.start(user.id).catchError((Object _) {}));
  ref.onDispose(service.dispose);
  return service;
});

final foregroundPushMessageProvider =
    StreamProvider.autoDispose<RemoteMessage>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  if (service == null) return const Stream<RemoteMessage>.empty();
  return service.foregroundMessages;
});
