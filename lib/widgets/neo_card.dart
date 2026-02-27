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
  final double borderRadius;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
    this.offset = 0.0,
    this.padding = const EdgeInsets.all(20.0),
    this.borderThickness = 2.0,
    this.borderRadius = 16.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark ? const Color(0xFF0A0A0A) : Colors.white),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.brand,
              width: borderThickness,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
