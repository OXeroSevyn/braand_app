import '../models/user.dart';

class LeaderboardEntry {
  final User user;
  final int score;
  final int tasksCompleted;
  final int moodPoints;
  final int attendancePoints;
  int rank;
  String trend; // 'UP', 'DOWN', 'STEADY'

  LeaderboardEntry({
    required this.user,
    required this.score,
    required this.tasksCompleted,
    this.moodPoints = 0,
    this.attendancePoints = 0,
    this.rank = 0,
    this.trend = 'STEADY',
  });
}
