import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../constants.dart';

class TaskCompletionBarChart extends StatelessWidget {
  final List<Task> tasks;
  final DateTime startDate;
  final DateTime endDate;

  const TaskCompletionBarChart({
    super.key,
    required this.tasks,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text("No data"));
    }

    final Map<int, Map<String, int>> dailyStats = {};
    // Iterate day by day
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final day = startDate.add(Duration(days: i));
      // Find tasks for this day
      final tasksForDay = tasks.where((t) => isSameDay(t.date, day));
      final completed = tasksForDay.where((t) => t.isCompleted).length;
      final pending = tasksForDay.length - completed;

      // Use day index 0-6 (or 0-N) for X axis
      dailyStats[i] = {'completed': completed, 'pending': pending};
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(dailyStats),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = startDate.add(Duration(days: group.x.toInt()));
                final status = rodIndex == 0 ? 'Completed' : 'Pending';
                return BarTooltipItem(
                  '${DateFormat('MM-dd').format(date)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '$status: ${rod.toY.toInt()}',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index > endDate.difference(startDate).inDays) {
                    return const SizedBox.shrink();
                  }
                  final date = startDate.add(Duration(days: index));
                  // Show title only for some days to avoid crowding
                  if (endDate.difference(startDate).inDays > 10 &&
                      index % 2 != 0) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd').format(date),
                      style: GoogleFonts.spaceMono(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.spaceMono(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            checkToShowHorizontalLine: (value) => value % 1 == 0,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailyStats.entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value['completed']!.toDouble(),
                  color: AppColors.brand,
                  width: 12,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: e.value['pending']!.toDouble(),
                  color: Colors.grey[300],
                  width: 12,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _calculateMaxY(Map<int, Map<String, int>> stats) {
    double max = 0;
    for (var s in stats.values) {
      if (s['completed']! > max) max = s['completed']!.toDouble();
      if (s['pending']! > max) max = s['pending']!.toDouble();
    }
    return max + 2; // buffer
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
