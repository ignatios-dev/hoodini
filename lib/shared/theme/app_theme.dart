import 'package:flutter/material.dart';

class AppTheme {
  // Street gold / neon on near-black
  static const _primary = Color(0xFFFFD700); // gold
  static const _bg = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF141414);
  static const _surfaceVariant = Color(0xFF1E1E1E);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          onPrimary: Colors.black,
          secondary: Color(0xFF39FF14), // neon green
          onSecondary: Colors.black,
          tertiary: Color(0xFFFF6B35),
          surface: _surface,
          onSurface: Colors.white,
          surfaceContainerHighest: _surfaceVariant,
          outline: Color(0xFF3A3A3A),
          error: Color(0xFFFF4444),
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF888888)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: _primary),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceVariant,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            backgroundColor: _surfaceVariant,
            foregroundColor: Colors.white,
            selectedBackgroundColor: _primary,
            selectedForegroundColor: Colors.black,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primary,
          foregroundColor: Colors.black,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      );
}
