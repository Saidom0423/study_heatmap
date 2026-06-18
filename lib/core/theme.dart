import 'package:flutter/material.dart';

class AppTheme {
  // Heatmap color scale (light → dark green, like GitHub)
  static const Color heat0 = Color(0xFF1A1A2E); // empty
  static const Color heat1 = Color(0xFF0D4A2F);
  static const Color heat2 = Color(0xFF1A7A4A);
  static const Color heat3 = Color(0xFF26A865);
  static const Color heat4 = Color(0xFF39D97E);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      primaryColor: const Color(0xFF39D97E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF39D97E),
        secondary: Color(0xFF26A865),
        surface: Color(0xFF16213E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF39D97E)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF39D97E),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}