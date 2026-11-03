import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const accentGradient = LinearGradient(
    colors: [Color(0xFF3978F6), Color(0xFF7954DF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6554D9),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F6FC),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
