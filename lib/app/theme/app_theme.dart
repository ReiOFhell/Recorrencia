import 'package:flutter/material.dart';

class AppTheme {
  static const _bg = Color(0xFF080808);
  static const _gold = Color(0xFFB08D57);
  static const _wine = Color(0xFF4A1F2B);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _gold,
          secondary: _wine,
          surface: Color(0xFF111111),
        ),
        cardColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: _bg, elevation: 0),
      );
}
