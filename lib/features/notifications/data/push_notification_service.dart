import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

class PushNotificationService {
  PushNotificationService(this._client, this._messaging);

  final SupabaseClient _client;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;

  Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  Future<void> start(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken(
      vapidKey: kIsWeb && Env.firebaseVapidKey.isNotEmpty
          ? Env.firebaseVapidKey
          : null,
    );

    if (token != null) {
      await _registerToken(userId: userId, token: token);
    }

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (refreshedToken) => unawaited(
        _registerToken(userId: userId, token: refreshedToken),
      ),
    );
  }

  Future<void> _registerToken({
    required String userId,
    required String token,
  }) async {
    await _client.from('device_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': _platformName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
