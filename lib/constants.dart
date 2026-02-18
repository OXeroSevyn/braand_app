import 'package:flutter/material.dart';

class AppColors {
  // Premium Brand Colors
  static const Color brand = Color(0xFF6F4CFF); // Electric Purple
  static const Color brandSecondary = Color(0xFF4AC6FF); // Electric Blue
  static const Color accent = Color(0xFFFF4C9D); // Neon Pink

  // Backgrounds
  // Deep Void Black for that OLED/Premium feel
  static const Color darkBackground = Color(0xFF030308);
  static const Color lightBackground = Color(0xFFF0F4F8);

  // Surface Colors for Glassmorphism
  static const Color darkSurface = Color(0xFF13131F);
  static const Color lightSurface = Colors.white;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand, brandSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xCC13131F), Color(0xCC0A0A10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static Color get shadowColor => const Color(0xFF6F4CFF).withOpacity(0.25);
}

class AppConstants {
  static const String appName = 'BRAANDINS';
}
