import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class EventCrewApp extends ConsumerWidget {
  const EventCrewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If compile-time Supabase config is missing, show a clear
    // developer-facing message instead of touching Supabase.instance
    // (which would throw) or silently running against nothing.
    if (!Env.isConfigured) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _MissingConfigScreen(),
      );
    }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest_outlined, size: 48, color: Colors.black54),
              const SizedBox(height: 16),
              const Text(
                'Supabase configuration missing',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
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
