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

    for (int i = 0; i < sortedRecords.length - 1; i++) {
      final current = sortedRecords[i];
      final next = sortedRecords[i + 1];

      if (current.type == AttendanceType.CLOCK_IN &&
          next.type == AttendanceType.CLOCK_OUT) {
        final start = DateTime.fromMillisecondsSinceEpoch(current.timestamp);
        final end = DateTime.fromMillisecondsSinceEpoch(next.timestamp);

        if (start.day == end.day) {
          total += end.difference(start);
        }
        i++;
      }
    }
    return total;
  }
}
