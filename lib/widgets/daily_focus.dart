import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import '../constants.dart';

class DailyFocus extends StatelessWidget {
  final List<String> topTasks;
  final String latestNotice;

  const DailyFocus({
    super.key,
    required this.topTasks,
    required this.latestNotice,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.05 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, size: 16, color: AppColors.brand),
              const SizedBox(width: 8),
              Text(
                'DAILY FOCUS',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topTasks.isEmpty && latestNotice.isEmpty)
            Text(
              'No high-priority items for today.',
              style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.grey),
            ),
          if (latestNotice.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.1),
                border: const Border(
                  left: BorderSide(color: AppColors.brand, width: 3),
                ),
              ),
              child: Text(
                '📢 $latestNotice',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...topTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_box_outline_blank,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task,
                        style: GoogleFonts.spaceMono(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
