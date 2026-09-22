import 'package:flutter/material.dart';

/// Centralised look and feel: clean, operational, no decorative
/// complexity. Card-like surfaces are built with plain [Container] +
/// [BoxDecoration] in each widget rather than a themed [Card], so this
/// file stays free of Flutter-version-sensitive theme-extension APIs.
class AppTheme {
  const AppTheme._();

  static const Color primary = Color(0xFF2757F2);
  static const Color surface = Color(0xFFF5F6FA);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF15803D);
  static const Color danger = Color(0xFFDC2626);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primary,
      scaffoldBackgroundColor: surface,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withOpacity(0.5),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}
