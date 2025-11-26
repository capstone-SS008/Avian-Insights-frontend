import 'package:flutter/material.dart';
import 'dart:ui';

class AppColors {
  static const Color headerGradientStart = Color(0xFF1e3c72);
  static const Color headerGradientEnd = Color(0xFF2a5298);
  static const Color bgGradientStart = Color(0xFF667eea);
  static const Color bgGradientEnd = Color(0xFF764ba2);
  static const Color cardBackground = Colors.white;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
    ),
  );
}
