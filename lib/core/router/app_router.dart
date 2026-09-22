import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/event_list_screen.dart';

/// Created once (not rebuilt on every auth event) so navigation state
/// isn't lost. [GoRouterRefreshStream] below is what tells go_router to
/// re-run [redirect] whenever Supabase's auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/events',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isSignedIn = ref.read(currentUserProvider) != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isSignedIn) return isLoggingIn ? null : '/login';
      if (isSignedIn && isLoggingIn) return '/events';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/events', builder: (context, state) => const EventListScreen()),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/chat',
        builder: (context, state) =>
            ChatScreen(eventId: state.pathParameters['eventId']!),
      ),
    ],
  );
});

/// Bridges a [Stream] to a [Listenable] so go_router re-evaluates its
/// `redirect` callback whenever Supabase's auth state changes (sign in,
/// sign out, token refresh) — without recreating the whole router.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
