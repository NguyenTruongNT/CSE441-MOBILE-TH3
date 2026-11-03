import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF202641);
  static const muted = Color(0xFF69718D);
  static const blue = Color(0xFF3477F5);
  static const violet = Color(0xFF7151E8);
  static const canvas = Color(0xFFF5F6FC);
  static const accentGradient = LinearGradient(
    colors: [Color(0xFF3978F6), Color(0xFF7954DF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF5D4DE0),
          secondary: blue,
          surface: Colors.white,
          onSurface: ink,
          onSurfaceVariant: muted,
          primaryContainer: const Color(0xFFECE9FF),
          outlineVariant: const Color(0xFFE3E6F1),
        );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'BeVietnamPro',
      fontFamilyFallback: const ['NotoSans', 'Roboto'],
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -0.7,
        ),
        headlineSmall: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          height: 1.35,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14.5, height: 1.55),
        bodySmall: TextStyle(fontSize: 12.5, height: 1.5),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ).apply(fontFamily: 'BeVietnamPro', bodyColor: ink, displayColor: ink),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE7EAF4)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE9E5FC),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE9E5FC),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F6FC),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F6FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
