import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Emits whenever Supabase auth changes (sign in, sign out, token
/// refresh). Supabase emits an initial event immediately on subscription,
/// reflecting any persisted session.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The signed-in user, or null. Falls back to the client's synchronous
/// `currentUser` so redirects work correctly on the very first frame,
/// before the auth stream has emitted its first event.
final currentUserProvider = Provider<User?>((ref) {
  final streamUser = ref.watch(authStateChangesProvider).valueOrNull?.session?.user;
  return streamUser ?? ref.watch(authRepositoryProvider).currentUser;
});

class SignInController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repo.signInWithPassword(email: email, password: password),
    );
    state = result;
    return !result.hasError;
  }
}

final signInControllerProvider =
    AsyncNotifierProvider<SignInController, void>(SignInController.new);
