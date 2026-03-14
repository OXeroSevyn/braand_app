import 'package:flutter/material.dart';
import 'dart:math' as math;

class RainbowButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Duration duration;
  final double height;
  final double borderRadius;
  final double borderWidth;

  final bool isSecondary;
  final bool isPurple;
  final bool isAmber;

  const RainbowButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isPurple = false,
    this.isAmber = false,
    this.duration = const Duration(seconds: 3),
    this.height = 54,
    this.borderRadius = 12,
    this.borderWidth = 2,
  });

  @override
  State<RainbowButton> createState() => _RainbowButtonState();
}

class _RainbowButtonState extends State<RainbowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isHovering && isEnabled ? 1.02 : 1.0,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                if (isEnabled)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                children: [
                  // Animated Rainbow Border
                  if (isEnabled)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _controller.value * 2 * math.pi,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                gradient: SweepGradient(
                                  colors: widget.isSecondary
                                      ? [
                                          Colors.grey,
                                          Colors.black,
                                          Colors.grey,
                                          Colors.black
                                        ]
                                      : widget.isPurple
                                          ? [
                                              Colors.purple,
                                              Colors.deepPurple,
                                              Colors.purple,
                                              Colors.deepPurple
                                            ]
                                          : widget.isAmber
                                              ? [
                                                  Colors.amber,
                                                  Colors.orange,
                                                  Colors.amber,
                                                  Colors.orange
                                                ]
                                              : [
                                                  Color(0xFFFF0000),
                                                  Color(0xFFFF7F00),
                                                  Color(0xFFFFFF00),
                                                  Color(0xFF00FF00),
                                                  Color(0xFF0000FF),
                                                  Color(0xFF4B0082),
                                                  Color(0xFF8B00FF),
                                                  Color(0xFFFF0000),
                                                ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Positioned.fill(
                      child: Container(color: colorScheme.surfaceContainer),
                    ),

                  // Button Content
                  Positioned.fill(
                    child: Container(
                      margin: EdgeInsets.all(widget.borderWidth),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? (colorScheme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                            widget.borderRadius - widget.borderWidth),
                      ),
                      child: Center(
                        child: widget.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary),
                                ),
                              )
                            : Text(
                                widget.text,
                                style: TextStyle(
                                  color: isEnabled
                                      ? (colorScheme.brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.38),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
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
}
