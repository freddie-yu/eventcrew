import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Fires on sign in, sign out, and token refresh. The router listens to
  /// this to decide between `/login` and the authenticated app.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (_) {
      throw const AppFailure('Incorrect email or password.');
    } catch (_) {
      throw const AppFailure('Could not sign in. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw const AppFailure('Could not sign out. Please try again.');
    }
  }
}
