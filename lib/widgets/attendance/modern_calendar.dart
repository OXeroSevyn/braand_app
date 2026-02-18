import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../models/attendance_record.dart';
import '../../utils/attendance_utils.dart';
import '../glass_container.dart';

class ModernCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<AttendanceRecord> records;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const ModernCalendar({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.records,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Month Selector
        _buildMonthHeader(isDark),
        const SizedBox(height: 20),

        // Calendar Grid
        GlassContainer(
          padding: const EdgeInsets.all(20),
          opacity: isDark ? 0.05 : 0.5,
          child: Column(
            children: [
              _buildWeekDays(isDark),
              const SizedBox(height: 12),
              _buildDaysGrid(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onMonthChanged(
            DateTime(currentMonth.year, currentMonth.month - 1),
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(currentMonth).toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onMonthChanged(
            DateTime(currentMonth.year, currentMonth.month + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDays(bool isDark) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    d,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDaysGrid(bool isDark) {
    final firstDay = AttendanceUtils.getFirstDayOfMonth(currentMonth);
    final lastDay = AttendanceUtils.getLastDayOfMonth(currentMonth);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: firstWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < firstWeekday) return const SizedBox();

        final day = index - firstWeekday + 1;
        final date = DateTime(currentMonth.year, currentMonth.month, day);
        final isSelected = date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        final isToday = date.day == DateTime.now().day &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;

        // Calculate status for dot
        final hours = AttendanceUtils.calculateTotalHours(records, date);
        final hasData = hours > 0;
        final statusColor =
            hasData ? _getStatusColor(hours) : Colors.transparent;

        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brand
                  : (isToday
                      ? (isDark ? Colors.white10 : Colors.grey[200])
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12), // Squircle shape
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.brand, width: 1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.black
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(double hours) {
    if (hours >= 8) return Colors.greenAccent;
    if (hours >= 4) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
