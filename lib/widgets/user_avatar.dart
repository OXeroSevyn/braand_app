import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable avatar widget that displays user profile pictures
/// Falls back to showing the first letter of the name if no picture is available
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final bool showBorder;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.size = 40,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColorFromName(name),
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: isDark ? Colors.white : Colors.black,
                width: 2,
              )
            : null,
        boxShadow: showBorder
            ? const [
                BoxShadow(
                  color: Color(0xFFCDFF00), // Brand color shadow
                  offset: Offset(2, 2),
                ),
              ]
            : null,
      ),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  // If image fails to load, show letter fallback
                  return _buildLetterFallback(firstLetter);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  // Show letter while loading
                  return _buildLetterFallback(firstLetter);
                },
              ),
            )
          : _buildLetterFallback(firstLetter),
    );
  }

  Widget _buildLetterFallback(String letter) {
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.spaceGrotesk(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  /// Generate a consistent color based on the user's name
  Color _getColorFromName(String name) {
    final colors = [
      const Color(0xFFCDFF00), // Lime (brand color)
      const Color(0xFFFF6B9D), // Pink
      const Color(0xFF00D9FF), // Cyan
      const Color(0xFFFFB800), // Amber
      const Color(0xFF9D00FF), // Purple
      const Color(0xFF00FF94), // Mint
    ];

    // Use name hash to pick a color
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}
