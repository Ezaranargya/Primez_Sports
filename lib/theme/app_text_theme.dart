import 'package:flutter/material.dart';

class AppTextTheme {
  static TextTheme textTheme = TextTheme(
    headlineLarge: const TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    headlineMedium: const TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    bodyLarge: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      height: 1.2,
      letterSpacing: 0.1,
    ),
    bodyMedium: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 1.2,
      letterSpacing: 0.1,
    )
  ); 
} 