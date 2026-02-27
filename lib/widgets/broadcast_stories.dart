import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../widgets/glass_container.dart';

class BroadcastStories extends StatelessWidget {
  final List<Map<String, String>> notices;
  final VoidCallback? onAddNotice;
  final Function(Map<String, String>)? onStoryTap;

  const BroadcastStories({
    super.key,
    required this.notices,
    this.onAddNotice,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TEAM BROADCASTS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (onAddNotice != null)
                IconButton(
                  onPressed: onAddNotice,
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.brand),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: notices.isEmpty ? 1 : notices.length,
            itemBuilder: (context, index) {
              if (notices.isEmpty) {
                return _buildEmptyState();
              }
              final notice = notices[index];
              return GestureDetector(
                onTap: () => onStoryTap?.call(notice),
                child: _buildStoryItem(notice),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoryItem(Map<String, String> notice) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.brand, Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.black,
              child: Text(
                _getEmoji(notice['category'] ?? 'INFO'),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notice['title'] ?? 'Notice',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceMono(
                fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GlassContainer(
        opacity: 0.1,
        child: Center(
          child: Text(
            'No active broadcasts',
            style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  String _getEmoji(String category) {
    switch (category.toUpperCase()) {
      case 'URGENT':
        return '🚨';
      case 'NEWS':
        return '📰';
      case 'EVENT':
        return '📅';
      case 'CELEBRATION':
        return '🎉';
      default:
        return '📢';
    }
  }
}
