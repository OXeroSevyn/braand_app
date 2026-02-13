import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final Widget? icon;
  final bool isLoading;

  const NeoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        widget.color ?? (isDark ? AppColors.brand : Colors.black);
    final effectiveTextColor =
        widget.textColor ?? (isDark ? Colors.black : Colors.white);

    // Soft glow matching the button color
    final shadowColor = effectiveColor.withOpacity(0.4);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.isLoading
                ? effectiveColor.withOpacity(0.7)
                : effectiveColor,
            borderRadius: BorderRadius.circular(16), // Rounded pill/rect
            boxShadow: [
              if (!_isPressed && !widget.isLoading)
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        effectiveTextColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        IconTheme(
                          data: IconThemeData(color: effectiveTextColor),
                          child: widget.icon!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          // Changed from Mono for cleaner look
                          color: effectiveTextColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
