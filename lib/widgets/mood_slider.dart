import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import '../constants.dart';

class MoodSlider extends StatefulWidget {
  final Function(String) onMoodSelected;

  const MoodSlider({super.key, required this.onMoodSelected});

  @override
  State<MoodSlider> createState() => _MoodSliderState();
}

class _MoodSliderState extends State<MoodSlider> {
  String? _selectedMood;
  final Map<String, String> _moods = {
    'rocket': '🚀',
    'smile': '😄',
    'coffee': '☕',
    'sleep': '😴',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      opacity: isDark ? 0.1 : 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HOW\'S THE ENERGY TODAY?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.entries.map((entry) {
              final isSelected = _selectedMood == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMood = entry.key);
                  widget.onMoodSelected(entry.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brand.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.brand : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
