import 'package:flutter/material.dart';
import 'dart:math' as math;

class LiquidProgressBar extends StatefulWidget {
  final double progress; // 0-100
  final double height;
  final String? timeRemaining;
  final bool isOverdue;

  const LiquidProgressBar({
    super.key,
    required this.progress,
    this.height = 60,
    this.timeRemaining,
    this.isOverdue = false,
  });

  @override
  State<LiquidProgressBar> createState() => _LiquidProgressBarState();
}

class _LiquidProgressBarState extends State<LiquidProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Color get _liquidColor {
    if (widget.isOverdue) return Colors.red;
    if (widget.progress >= 80) return Colors.orange;
    if (widget.progress >= 50) return Colors.yellow[700]!;
    return const Color(0xFFCDFF00); // Brand color
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.white : Colors.black,
          width: 2,
        ),
        color: isDark ? Colors.black : Colors.grey[100],
      ),
      child: Stack(
        children: [
          // Animated liquid wave
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return ClipRect(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LiquidWavePainter(
                    progress: widget.progress / 100,
                    wavePhase: _waveController.value,
                    color: _liquidColor,
                  ),
                ),
              );
            },
          ),
          // Progress text overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.progress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.progress > 50
                        ? Colors.black
                        : (isDark ? Colors.white : Colors.black),
                    shadows: widget.progress > 50
                        ? [
                            Shadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                if (widget.timeRemaining != null)
                  Text(
                    widget.timeRemaining!,
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.progress > 50
                          ? Colors.black87
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double wavePhase; // 0.0 to 1.0, for animation
  final Color color;

  _LiquidWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.05; // Wave amplitude
    final waveLength = size.width;

    // Start from bottom left
    final liquidLevel = size.height * (1 - progress);

    // Create wavy top edge
    path.moveTo(0, liquidLevel);

    for (double i = 0; i <= size.width; i++) {
      final x = i;
      final y = liquidLevel +
          math.sin((i / waveLength * 2 * math.pi) + (wavePhase * 2 * math.pi)) *
              waveHeight;
      path.lineTo(x, y);
    }

    // Complete the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color;
  }
}
