import '../models/attendance_record.dart';

class AttendanceUtils {
  /// Calculate total work hours for a specific date
  /// Pairs CLOCK_IN with CLOCK_OUT and subtracts break time
  static double calculateTotalHours(
      List<AttendanceRecord> records, DateTime date) {
    final dateRecords = getAttendanceForDate(records, date);
    if (dateRecords.isEmpty) return 0.0;

    final sessions = getWorkSessions(dateRecords);
    double totalMinutes = 0.0;

    for (var session in sessions) {
      totalMinutes += session['minutes'] as double;
    }

    return totalMinutes / 60.0; // Convert to hours
  }

  /// Calculate total hours for the current week (Monday - Sunday)
  static double calculateWeeklyHours(List<AttendanceRecord> records) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    double totalHours = 0.0;
    for (int i = 0; i < 7; i++) {
      final date = weekStartDate.add(Duration(days: i));
      totalHours += calculateTotalHours(records, date);
    }

    return totalHours;
  }

  /// Calculate total hours for a specific month
  static double calculateMonthlyHours(
      List<AttendanceRecord> records, int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    double totalHours = 0.0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      totalHours += calculateTotalHours(records, date);
    }

    return totalHours;
  }

  /// Calculate total hours across all records
  static double calculateAllTimeHours(List<AttendanceRecord> records) {
    if (records.isEmpty) return 0.0;

    // Group by unique dates
    final uniqueDates = <DateTime>{};
    for (var record in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      uniqueDates.add(DateTime(date.year, date.month, date.day));
    }

    double totalHours = 0.0;
    for (var date in uniqueDates) {
      totalHours += calculateTotalHours(records, date);
    }

    return totalHours;
  }

  /// Get all attendance records for a specific date
  static List<AttendanceRecord> getAttendanceForDate(
      List<AttendanceRecord> records, DateTime date) {
    return records.where((record) {
      final recordDate = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      return recordDate.year == date.year &&
          recordDate.month == date.month &&
          recordDate.day == date.day;
    }).toList();
  }

  /// Parse records into work sessions with calculated minutes
  /// Returns list of sessions with start, end, and minutes worked
  static List<Map<String, dynamic>> getWorkSessions(
      List<AttendanceRecord> records) {
    final sessions = <Map<String, dynamic>>[];

    // Sort by timestamp
    final sortedRecords = List<AttendanceRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    AttendanceRecord? clockIn;
    AttendanceRecord? breakStart;
    double breakMinutes = 0.0;

    for (var record in sortedRecords) {
      switch (record.type) {
        case AttendanceType.CLOCK_IN:
          clockIn = record;
          breakMinutes = 0.0;
          break;

        case AttendanceType.BREAK_START:
          breakStart = record;
          break;

        case AttendanceType.BREAK_END:
          if (breakStart != null) {
            final breakDuration = record.timestamp - breakStart.timestamp;
            breakMinutes += breakDuration / (1000 * 60); // Convert to minutes
            breakStart = null;
          }
          break;

        case AttendanceType.CLOCK_OUT:
          if (clockIn != null) {
            final totalDuration = record.timestamp - clockIn.timestamp;
            final totalMinutes = totalDuration / (1000 * 60);
            final workMinutes = totalMinutes - breakMinutes;

            sessions.add({
              'clockIn': clockIn,
              'clockOut': record,
              'minutes': workMinutes > 0 ? workMinutes : 0.0,
              'breakMinutes': breakMinutes,
            });

            clockIn = null;
            breakMinutes = 0.0;
          }
          break;
      }
    }

    // Handle case where user clocked in but hasn't clocked out yet
    if (clockIn != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final totalDuration = now - clockIn.timestamp;
      final totalMinutes = totalDuration / (1000 * 60);
      final workMinutes = totalMinutes - breakMinutes;

      sessions.add({
        'clockIn': clockIn,
        'clockOut': null, // Still active
        'minutes': workMinutes > 0 ? workMinutes : 0.0,
        'breakMinutes': breakMinutes,
      });
    }

    return sessions;
  }

  /// Get day status based on hours worked
  /// Returns: 'full' (8+ hrs), 'partial' (4-8 hrs), 'minimal' (<4 hrs), 'none' (0 hrs)
  static String getDayStatus(double hours) {
    if (hours >= 8.0) return 'full';
    if (hours >= 4.0) return 'partial';
    if (hours > 0.0) return 'minimal';
    return 'none';
  }

  /// Format hours to readable string (e.g., "8.5h" or "8h 30m")
  static String formatHours(double hours, {bool detailed = false}) {
    if (hours == 0) return '0h';

    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();

    if (detailed && minutes > 0) {
      return '${wholeHours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      return '${wholeHours}h';
    }
  }

  /// Get the first day of the month for a given date
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the last day of the month for a given date
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get list of months for the last N months
  static List<DateTime> getLastNMonths(int n) {
    final now = DateTime.now();
    final months = <DateTime>[];

    for (int i = 0; i < n; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add(month);
    }

    return months;
  }
}
