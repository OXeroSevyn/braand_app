import 'package:flutter/material.dart';
import '../constants.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double offset; // Kept for API compatibility
  final EdgeInsetsGeometry padding;
  final double borderThickness; // Kept for compatibility

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

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? Colors.black : Colors.white),
        border: Border.all(
          color: borderColor ?? AppColors.brand,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? (isDark ? Colors.black : Colors.black),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
