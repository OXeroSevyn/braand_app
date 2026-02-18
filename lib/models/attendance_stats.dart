class AttendanceStats {
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final double averageHours;
  final int totalWorkingDays;

  AttendanceStats({
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.averageHours,
    required this.totalWorkingDays,
  });

  factory AttendanceStats.empty() {
    return AttendanceStats(
      presentDays: 0,
      lateDays: 0,
      absentDays: 0,
      averageHours: 0.0,
      totalWorkingDays: 0,
    );
  }
}
