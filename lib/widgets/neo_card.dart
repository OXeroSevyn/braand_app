import 'package:flutter/material.dart';
import '../constants.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double offset; // Kept for API compatibility, but used for elevation
  final EdgeInsetsGeometry padding;
  final double borderThickness; // Kept for compatibility, mostly unused

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
    this.offset = 8.0,
    this.padding = const EdgeInsets.all(24.0),
    this.borderThickness = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBackgroundColor =
        backgroundColor ?? (isDark ? AppColors.darkSurface : Colors.white);

    // Modern shadow color (softer)
    final effectiveShadowColor = shadowColor ??
        (isDark
            ? Colors.black.withOpacity(0.5)
            : Colors.black.withOpacity(0.05));

    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(24.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: effectiveShadowColor,
            offset: const Offset(0, 4), // Soft bottom shadow
            blurRadius: 16.0,
            spreadRadius: 0,
          ),
          // Add a subtle border for contrast in dark mode
          if (isDark)
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              offset: const Offset(0, 0),
              blurRadius: 0,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
