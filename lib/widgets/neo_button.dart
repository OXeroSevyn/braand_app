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
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoading();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
        },
        onTapUp: (_) {
          _controller.reverse();
        },
        onTapCancel: () {
          _controller.reverse();
        },
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Glow effect
                if (_isHovered && !widget.isLoading)
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.6),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                else
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: widget.icon!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withOpacity(0.5)),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
          ),
        ),
      ),
    );
  }
}
