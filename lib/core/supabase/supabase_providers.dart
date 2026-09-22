import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The single Supabase client instance, initialized once in `main()`
/// before the app runs (see main.dart / core/config/env.dart). Every
/// repository depends on this provider rather than calling
/// `Supabase.instance.client` directly, which keeps repositories easy to
/// override in tests.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
