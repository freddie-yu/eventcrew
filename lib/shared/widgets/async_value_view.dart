import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_failure.dart';

/// Renders loading / error / data states for an [AsyncValue] consistently
/// across screens, so each feature screen only has to describe its
/// success UI. Used to satisfy the "every network-backed screen handles
/// loading, empty and error" requirement without repeating boilerplate.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorView(
        message: friendlyErrorMessage(error),
        onRetry: onRetry,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Converts any error into a short, user-safe message. Never surfaces raw
/// Supabase/Postgres exception text to the UI — see [AppFailure].
String friendlyErrorMessage(Object error) {
  if (error is AppFailure) return error.message;
  return 'Something went wrong. Please try again.';
}
