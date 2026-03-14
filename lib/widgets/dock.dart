import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DockIconData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasBadge;
  final String? badgeLabel;

  DockIconData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasBadge = false,
    this.badgeLabel,
  });
}

class Dock extends StatefulWidget {
  final List<DockIconData> items;
  final int currentIndex;

  const Dock({
    super.key,
    required this.items,
    required this.currentIndex,
  });

  @override
  State<Dock> createState() => _DockState();
}

class _DockState extends State<Dock> {
  double _hoverIndex = -1;
  static const double _baseSize = 48.0;
  static const double _magnification = 1.6;
  static const double _distance = 2.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _hoverIndex = _calculateHoverIndex(event.localPosition.dx);
        });
      },
      onExit: (_) {
        setState(() {
          _hoverIndex = -1;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.items.length, (index) {
                return _buildDockIcon(index, colorScheme);
              }),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateHoverIndex(double x) {
    // Calculate hover index based on horizontal position
    // Each item has a base size plus margin
    const itemFullWidth = _baseSize + 12.0; // _baseSize + (6 * 2) margin
    double relativeX = x - 12.0; // Subtract padding
    double index = relativeX / itemFullWidth;

    if (index < -0.5 || index > widget.items.length - 0.5) return -1;
    return index;
  }

  double _getIconWidth(int index) {
    if (_hoverIndex == -1) return _baseSize;

    // Smooth bell curve based on distance
    double distance = (index + 0.5 - _hoverIndex).abs();
    if (distance > _distance) return _baseSize;

    // Cosine-based smoothing for the magnification curve
    double t = distance / _distance;
    double factor = 1.0 +
        (_magnification - 1.0) * (0.5 + 0.5 * (1.0 - t * t).clamp(0.0, 1.0));

    return _baseSize * factor;
  }

  Widget _buildDockIcon(int index, ColorScheme colorScheme) {
    bool isSelected = index == widget.currentIndex;
    final item = widget.items[index];

    double size = _getIconWidth(index);

    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: size * 0.5,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (item.hasBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        item.badgeLabel ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        )
            .animate(target: isSelected ? 1 : 0)
            .shimmer(duration: 2.seconds, color: Colors.white24),
      ),
    );
  }
}
