import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement.dart';
import 'glass_container.dart';
import '../constants.dart';

class BadgeGallery extends StatelessWidget {
  final List<Achievement> achievements;

  const BadgeGallery({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'ACHIEVEMENTS',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _buildBadgeCard(achievement);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Achievement achievement) {
    return GlassContainer(
      opacity: achievement.isUnlocked ? 0.15 : 0.05,
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? AppColors.brand.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.brand.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 32,
                color: achievement.isUnlocked
                    ? null
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: achievement.isUnlocked ? Colors.white : Colors.white38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 8,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          if (!achievement.isUnlocked)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(achievement.progress * 100).toInt()}%',
                  style: GoogleFonts.spaceMono(fontSize: 8, color: Colors.grey),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brand.withOpacity(0.5)),
              ),
              child: Text(
                'UNLOCKED',
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
