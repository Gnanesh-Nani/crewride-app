import 'package:flutter/material.dart';

enum AppTheme {
  light('Light'),
  dark('Dark'),
  green('Green Current');

  final String label;
  const AppTheme(this.label);
}

class AppThemes {
  static ThemeData buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1C64F2),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
        secondary: Color(0xFF6B7280),
      ),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C64F2),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade200.withOpacity(0.4)),
          ),
        ),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF5B9EFF),
        onPrimary: Color(0xFF0B1220),
        surface: Color(0xFF0F172A),
        onSurface: Colors.white,
        secondary: Color(0xFF94A3B8),
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      dividerColor: Colors.white10,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B9EFF),
          foregroundColor: const Color(0xFF0B1220),
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade700.withOpacity(0.4)),
          ),
        ),
      ),
    );
  }

  static ThemeData buildGreenTheme() {
    // Green theme inspired by lovable-template-react
    // Primary Green: hsl(142 76% 46%) = #10b981
    // Dark background: hsl(222 47% 8%) = #0f1729
    // Secondary slate: hsl(222 47% 15%) = #1a254a

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF10b981), // Crew green
        onPrimary: Color(0xFF0f1729),
        surface: Color(0xFF0f1729), // Dark background
        onSurface: Colors.white,
        secondary: Color(0xFF1a254a), // Slate
      ),
      scaffoldBackgroundColor: const Color(0xFF0f1729),
      dividerColor: Colors.white10,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0f1729),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1a254a),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10b981), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10b981), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10b981), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10b981),
          foregroundColor: const Color(0xFF0f1729),
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF10b981), width: 0.5),
          ),
        ),
      ),
    );
  }

  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return buildLightTheme();
      case AppTheme.dark:
        return buildDarkTheme();
      case AppTheme.green:
        return buildGreenTheme();
    }
  }
}
