import 'package:eventcrew/core/error/app_failure.dart';
import 'package:eventcrew/core/error/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapUniqueViolation', () {
    test('maps a 23505 unique violation (duplicate join / duplicate clock-in) '
        'to the duplicate message', () {
      final error = PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );

      final failure = mapUniqueViolation(
        error,
        duplicateMessage: "You've already joined this shift.",
        genericMessage: 'Could not join this shift. Please try again.',
      );

      expect(failure, isA<AppFailure>());
      expect(failure.message, "You've already joined this shift.");
    });

    test('maps a non-duplicate Postgrest error to the generic message', () {
      final error = PostgrestException(message: 'network error', code: '500');

      final failure = mapUniqueViolation(
        error,
        duplicateMessage: "You've already joined this shift.",
        genericMessage: 'Could not join this shift. Please try again.',
      );

      expect(failure.message, 'Could not join this shift. Please try again.');
    });

    test('maps a non-Postgrest error to the generic message', () {
      final failure = mapUniqueViolation(
        Exception('boom'),
        duplicateMessage: 'duplicate',
        genericMessage: 'generic',
      );

      expect(failure.message, 'generic');
    });
  });
}
