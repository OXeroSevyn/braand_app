import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../models/attendance_record.dart';
import '../../utils/attendance_utils.dart';
import '../glass_container.dart';

class GradientTimeline extends StatelessWidget {
  final List<AttendanceRecord> records;
  final DateTime selectedDate;
  final double totalHours;

  const GradientTimeline({
    super.key,
    required this.records,
    required this.selectedDate,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayRecords =
        AttendanceUtils.getAttendanceForDate(records, selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIMELINE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, Color(0xFFD4FF7A)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${totalHours.toStringAsFixed(1)} HRS',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (dayRecords.isEmpty)
          _buildEmptyState(isDark)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayRecords.length,
            itemBuilder: (context, index) {
              final record = dayRecords[index];
              return _buildTimelineItem(context, record, index == 0,
                  index == dayRecords.length - 1, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        opacity: 0.05,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No logs for this day',
              style: GoogleFonts.spaceMono(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, AttendanceRecord record,
      bool isFirst, bool isLast, bool isDark) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('h:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(record.timestamp)),
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  DateFormat('a').format(
                      DateTime.fromMillisecondsSinceEpoch(record.timestamp)),
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Line & Dot
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: isFirst
                    ? Colors.transparent
                    : (isDark ? Colors.white24 : Colors.grey[300]),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getColor(record.type),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.black : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getColor(record.type).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : (isDark ? Colors.white24 : Colors.grey[300]),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                opacity: 0.03,
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getColor(record.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIcon(record.type),
                        color: _getColor(record.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLabel(record.type),
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (record.location != null)
                          Text(
                            '📍 ${record.location}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return Colors.greenAccent;
      case AttendanceType.CLOCK_OUT:
        return Colors.redAccent;
      case AttendanceType.BREAK_START:
        return Colors.orangeAccent;
      case AttendanceType.BREAK_END:
        return Colors.blueAccent;
    }
  }

  IconData _getIcon(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return Icons.login;
      case AttendanceType.CLOCK_OUT:
        return Icons.logout;
      case AttendanceType.BREAK_START:
        return Icons.coffee;
      case AttendanceType.BREAK_END:
        return Icons.work;
    }
  }

  String _getLabel(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return 'CLOCKED IN';
      case AttendanceType.CLOCK_OUT:
        return 'CLOCKED OUT';
      case AttendanceType.BREAK_START:
        return 'ON BREAK';
      case AttendanceType.BREAK_END:
        return 'BACK TO WORK';
    }
  }
}
