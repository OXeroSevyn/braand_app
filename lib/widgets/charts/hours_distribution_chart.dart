import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task_report_data.dart';
import '../../constants.dart';

class HoursDistributionPieChart extends StatefulWidget {
  final List<TaskReportData> reportData;

  const HoursDistributionPieChart({super.key, required this.reportData});

  @override
  State<HoursDistributionPieChart> createState() =>
      _HoursDistributionPieChartState();
}

class _HoursDistributionPieChartState extends State<HoursDistributionPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.reportData.isEmpty ||
        widget.reportData.every((r) => r.totalHours == 0)) {
      return const Center(child: Text("No data"));
    }

    // Filter out users with 0 hours
    final data = widget.reportData.where((r) => r.totalHours > 0).toList();

    return Row(
      children: <Widget>[
        const SizedBox(
          height: 18,
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: showingSections(data),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Indicator(
                color: _getColor(index),
                text: report.user.name,
                isSquare: true,
              ),
            );
          }).toList(),
        ),
        const SizedBox(
          width: 28,
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections(List<TaskReportData> data) {
    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final report = data[i];
      final color = _getColor(i);

      return PieChartSectionData(
        color: color,
        value: report.totalHours,
        title: '${report.totalHours.toStringAsFixed(1)}h',
        radius: radius,
        titleStyle: GoogleFonts.spaceMono(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getColor(int index) {
    const colors = [
      AppColors.brand,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.indigo,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 12,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}
