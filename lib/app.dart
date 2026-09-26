import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/push_providers.dart';

class EventCrewApp extends ConsumerWidget {
  const EventCrewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isConfigured) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _MissingConfigScreen(),
      );
    }

    // Push is optional. Watching this provider registers the current device
    // token when Firebase is configured and keeps the registration lifecycle
    // tied to the authenticated user.
    ref.watch(pushNotificationServiceProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'EventCrew',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F5F7),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_suggest_outlined,
                size: 48,
                color: Colors.black54,
              ),
              SizedBox(height: 16),
              Text(
                'Supabase configuration missing',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Run the app with --dart-define=SUPABASE_URL=... and '
                '--dart-define=SUPABASE_ANON_KEY=... (see README.md).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
