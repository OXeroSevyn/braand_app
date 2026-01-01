import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SnowfallOverlay extends StatefulWidget {
  final Widget child;

  const SnowfallOverlay({super.key, required this.child});

  @override
  State<SnowfallOverlay> createState() => _SnowfallOverlayState();
}

class _SnowfallOverlayState extends State<SnowfallOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<Snowflake> _snowflakes = [];
  final Random _random = Random();
  Size? _size;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_size == null) return;

    // Generate snowflakes locally
    if (_random.nextDouble() < 0.1 && _snowflakes.length < 200) {
      _snowflakes.add(Snowflake(
        x: _random.nextDouble() * _size!.width,
        y: -10,
        size: _random.nextDouble() * 2 + 1, // Size 1-3
        speed: _random.nextDouble() * 0.6 + 0.2, // Speed 0.2-0.8 (Slower)
        opacity: _random.nextDouble() * 0.4 + 0.1, // Opacity 0.1-0.5
      ));
    }

    for (var i = _snowflakes.length - 1; i >= 0; i--) {
      final flake = _snowflakes[i];
      flake.y += flake.speed;

      if (flake.y > _size!.height) {
        _snowflakes.removeAt(i);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            widget.child,
            IgnorePointer(
              child: CustomPaint(
                size: _size!,
                painter: SnowfallPainter(_snowflakes),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Snowflake {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class SnowfallPainter extends CustomPainter {
  final List<Snowflake> snowflakes;

  SnowfallPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var flake in snowflakes) {
      paint.color = Colors.white.withOpacity(flake.opacity);
      canvas.drawCircle(Offset(flake.x, flake.y), flake.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
