import 'attendance_record.dart';
import 'user.dart';

class ReportData {
  final User user;
  final List<AttendanceRecord> records;

  ReportData({required this.user, required this.records});

  int get totalDaysPresent {
    final uniqueDays = <String>{};
    for (var record in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      uniqueDays.add('${date.year}-${date.month}-${date.day}');
    }
    return uniqueDays.length;
  }

  Duration get totalHoursWorked {
    Duration total = Duration.zero;

    final sortedRecords = List<AttendanceRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    DateTime? lastStartTime;

    for (var record in sortedRecords) {
      if (record.type == AttendanceType.CLOCK_IN ||
          record.type == AttendanceType.BREAK_END) {
        lastStartTime = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      } else if ((record.type == AttendanceType.CLOCK_OUT ||
              record.type == AttendanceType.BREAK_START) &&
          lastStartTime != null) {
        final endTime = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
        // Only count if within same day (sanity check)
        if (endTime.day == lastStartTime.day) {
          total += endTime.difference(lastStartTime);
        }
        lastStartTime = null;
      }
    }

    // Handle ongoing session (Clocked In but not Clocked Out)
    // Only if the start time is today, we count it up to "now"
    if (lastStartTime != null) {
      final now = DateTime.now();
      if (lastStartTime.year == now.year &&
          lastStartTime.month == now.month &&
          lastStartTime.day == now.day) {
        total += now.difference(lastStartTime);
      }
    }

    return total;
  }
}
