import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../widgets/glass_container.dart';

class VibeHeatmap extends StatelessWidget {
  final Map<String, int> moodCounts;

  const VibeHeatmap({super.key, required this.moodCounts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = moodCounts.values.fold(0, (sum, count) => sum + count);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      opacity: isDark ? 0.05 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: AppColors.brand, size: 20),
              const SizedBox(width: 8),
              Text(
                'TEAM ENERGY HEATMAP',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: total == 0
                ? _buildEmptyState()
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (moodCounts.values.isEmpty
                              ? 0
                              : moodCounts.values
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble()) +
                          1,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final moods = ['🚀', '😄', '☕', '😴'];
                              if (value >= 0 && value < moods.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(moods[value.toInt()],
                                      style: const TextStyle(fontSize: 16)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _buildBarGroup(0, moodCounts['rocket']?.toDouble() ?? 0,
                            Colors.orange),
                        _buildBarGroup(1, moodCounts['smile']?.toDouble() ?? 0,
                            Colors.green),
                        _buildBarGroup(2, moodCounts['coffee']?.toDouble() ?? 0,
                            Colors.brown),
                        _buildBarGroup(3, moodCounts['sleep']?.toDouble() ?? 0,
                            Colors.blue),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: color.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Insufficient vibe data for today.',
        style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.grey),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem('ROCKET', Colors.orange),
        _legendItem('HAPPY', Colors.green),
        _legendItem('COFFEE', Colors.brown),
        _legendItem('TIRED', Colors.blue),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.spaceMono(
                fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
