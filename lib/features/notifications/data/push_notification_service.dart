import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_push_bridge_stub.dart'
    if (dart.library.html) 'web_push_bridge_web.dart';

class PushNotificationService {
  PushNotificationService(this._client, this._messaging);

  final SupabaseClient _client;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;

  Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  Future<bool> isRegistered(String userId) async {
    final rows = await _client
        .from('device_tokens')
        .select('id')
        .eq('user_id', userId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  /// Enables push from an explicit user action.
  ///
  /// Web uses an explicit JS service-worker registration so deployments under
  /// a sub-path (such as GitHub Pages /eventcrew/) do not depend on Firebase's
  /// default root-level /firebase-messaging-sw.js lookup.
  Future<bool> enableForUser(String userId) async {
    if (kIsWeb) {
      final token = await requestWebPushToken();
      if (token == null || token.isEmpty) return false;
      await _registerToken(userId: userId, token: token);
      return true;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    final token = await _messaging.getToken();
    if (token == null) return false;

    await _registerToken(userId: userId, token: token);

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (refreshedToken) => unawaited(
        _registerToken(userId: userId, token: refreshedToken),
      ),
    );
    return true;
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
