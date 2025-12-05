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

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        widget.color ?? (isDark ? AppColors.brand : Colors.black);
    final effectiveTextColor =
        widget.textColor ?? (isDark ? Colors.black : Colors.white);
    final shadowColor = isDark ? Colors.white : Colors.black.withOpacity(0.2);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.isLoading
                ? effectiveColor.withOpacity(0.7)
                : effectiveColor,
            border: Border.all(
              color: isDark ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: shadowColor,
                      offset: const Offset(6, 6),
                      blurRadius: 0,
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
                        widget.icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text.toUpperCase(),
                        style: GoogleFonts.spaceMono(
                          color: effectiveTextColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
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
