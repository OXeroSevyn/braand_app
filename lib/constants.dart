import 'package:flutter/material.dart';

class AppColors {
  // Premium Brand Colors - NEON GREEN REVERTED
  static const Color brand = Color(0xFFA7FE2B); // Neon Green
  static const Color brandSecondary =
      Color(0xFF8EDD22); // Slightly darker for gradients/hover
  static const Color accent = Colors.white;

  // Backgrounds
  static const Color darkBackground = Colors.black;
  static const Color lightBackground = Color(0xFFF0F4F8);

  // Surface Colors for Glassmorphism
  static const Color darkSurface =
      Color(0xFF151515); // Slightly lighter than black for cards
  static const Color lightSurface = Colors.white;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand, brandSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xCC151515), Color(0xCC050505)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static Color get shadowColor => brand.withOpacity(0.25);
}

class AppConstants {
  static const String appName = 'BRAANDINS';
}
