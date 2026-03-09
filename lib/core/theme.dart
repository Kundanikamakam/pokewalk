import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3B5BA5);
  static const Color accentColor = Color(0xFFEE1515);
  static const Color surfaceColor = Color(0xFFF5F5F5);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          secondary: accentColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          toolbarHeight: 48,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
      );
}
