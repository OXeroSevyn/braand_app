import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../glass_container.dart';

class GradientMessageBubble extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final bool isMe;
  final bool isFirstInSequence;

  const GradientMessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isMe,
    this.isFirstInSequence = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4,
          left: isMe ? 50 : 0,
          right: isMe ? 0 : 50,
          top: isFirstInSequence ? 12 : 0,
        ),
        child: isMe ? _buildMyMessage(isDark) : _buildOtherMessage(isDark),
      ),
    );
  }

  Widget _buildMyMessage(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, Color(0xFF8BC34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: const Radius.circular(20),
          bottomRight: isFirstInSequence
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              color: Colors.black, // Always black on brand color
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(timestamp),
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMessage(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      opacity: isDark ? 0.1 : 0.6,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
        bottomLeft: isFirstInSequence
            ? const Radius.circular(4)
            : const Radius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(timestamp),
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
