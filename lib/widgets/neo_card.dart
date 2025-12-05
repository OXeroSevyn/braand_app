import 'package:flutter/material.dart';
import '../constants.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double offset;
  final EdgeInsetsGeometry padding;
  final double borderThickness;

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
    final effectiveShadowColor =
        shadowColor ?? (isDark ? AppColors.brand : Colors.black);
    final effectiveBorderColor =
        borderColor ?? (isDark ? Colors.white : Colors.black);
    final effectiveBackgroundColor =
        backgroundColor ?? (isDark ? AppColors.darkSurface : Colors.white);

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          // Shadow
          Positioned(
            top: offset,
            left: offset,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(color: effectiveShadowColor),
            ),
          ),
          // Content
          Container(
            margin: EdgeInsets.only(bottom: offset, right: offset),
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              border: Border.all(
                color: effectiveBorderColor,
                width: borderThickness,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
