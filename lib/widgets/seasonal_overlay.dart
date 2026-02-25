import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum Season { winter, spring, summer, autumn }

class SeasonalOverlay extends StatefulWidget {
  final Widget child;

  const SeasonalOverlay({super.key, required this.child});

  @override
  State<SeasonalOverlay> createState() => _SeasonalOverlayState();
}

class _SeasonalOverlayState extends State<SeasonalOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<Particle> _particles = [];
  final Random _random = Random();
  Size? _size;
  late Season _currentSeason;

  @override
  void initState() {
    super.initState();
    _currentSeason = _getSeason();
    _ticker = createTicker(_onTick)..start();
  }

  Season _getSeason() {
    final month = DateTime.now().month;
    if (month == 12 || month == 1 || month == 2) return Season.winter;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    return Season.autumn; // 9, 10, 11
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_size == null) return;

    // Determine particle limit and generation rate based on season
    bool isWeb = kIsWeb; // I need to import foundation here too
    int limit = isWeb ? 40 : 100;
    double generationRate = isWeb ? 0.05 : 0.1;

    if (_currentSeason == Season.summer) {
      limit = isWeb ? 20 : 40; // Fewer fireflies
      generationRate = isWeb ? 0.01 : 0.02;
    }

    // Generate particles
    if (_random.nextDouble() < generationRate && _particles.length < limit) {
      _spawnParticle();
    }

    // Update particles
    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];

      // Movement
      p.x += p.dx;
      p.y += p.dy;

      // Behavior per season
      if (_currentSeason == Season.spring || _currentSeason == Season.autumn) {
        // Swaying
        p.dx += (_random.nextDouble() - 0.5) * 0.1;
        // Limit horizontal speed
        p.dx = p.dx.clamp(-1.0, 1.0);
      } else if (_currentSeason == Season.summer) {
        // Fireflies move erratically
        p.dx += (_random.nextDouble() - 0.5) * 0.2;
        p.dy += (_random.nextDouble() - 0.5) * 0.2;
        // Keep them bounded roughly or let them wrap?
        // Let's just fade them out if they move too far
      }

      // Check bounds using a safe margin
      bool remove = false;
      if (p.y > _size!.height + 20) remove = true; // Bottom
      if (p.y < -50 && _currentSeason != Season.summer)
        remove = true; // Top (snow/leaves don't go up)
      if (_currentSeason == Season.summer &&
          (p.y < -20 || p.x < -20 || p.x > _size!.width + 20)) remove = true;
      if (p.opacity <= 0) remove = true;

      // Twinkle/Fade for fireflies
      if (_currentSeason == Season.summer) {
        p.opacity += (_random.nextDouble() - 0.5) * 0.05;
        p.opacity = p.opacity.clamp(0.0, 1.0);
      }

      if (remove) {
        _particles.removeAt(i);
      }
    }

    setState(() {});
  }

  void _spawnParticle() {
    double x = _random.nextDouble() * _size!.width;
    double y = -10;
    double size = _random.nextDouble() * 3 + 2;
    double dy = _random.nextDouble() * 1.5 + 0.5; // Default falling speed
    double dx = 0;
    Color color = Colors.white;
    double opacity = _random.nextDouble() * 0.5 + 0.3;

    switch (_currentSeason) {
      case Season.winter:
        size = _random.nextDouble() * 3 + 2;
        dy = _random.nextDouble() * 2 + 1;
        opacity = _random.nextDouble() * 0.6 + 0.2;
        break;
      case Season.spring:
        // Petals
        color = _random.nextBool()
            ? const Color(0xFFFFB7C5)
            : Colors.white; // Pink or White
        size = _random.nextDouble() * 4 + 3;
        dy = _random.nextDouble() * 1 + 0.5;
        dx = (_random.nextDouble() - 0.5) * 0.5;
        break;
      case Season.summer:
        // Fireflies
        y = _random.nextDouble() * _size!.height; // Spawn anywhere
        color = const Color(0xFFFFD700); // Gold
        size = _random.nextDouble() * 3 + 2;
        dy = (_random.nextDouble() - 0.5) * 1; // Float any direction
        dx = (_random.nextDouble() - 0.5) * 1;
        opacity = 0; // Fade in
        break;
      case Season.autumn:
        // Leaves
        List<Color> autumnColors = [
          const Color(0xFFD35400), // Pumpkin
          const Color(0xFFE67E22), // Carrot
          const Color(0xFFA04000), // Brown
          const Color(0xFFF1C40F), // Yellow
        ];
        color = autumnColors[_random.nextInt(autumnColors.length)];
        size = _random.nextDouble() * 5 + 4;
        dy = _random.nextDouble() * 1.5 + 0.5;
        dx = (_random.nextDouble() - 0.5) * 1;
        break;
    }

    _particles.add(Particle(
      x: x,
      y: y,
      size: size,
      dx: dx,
      dy: dy,
      opacity: opacity,
      color: color,
    ));
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
                painter: ParticlePainter(_particles),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double dx; // Horizontal speed
  double dy; // Vertical speed
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.dx,
    required this.dy,
    required this.opacity,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      paint.color = p.color.withOpacity(p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
