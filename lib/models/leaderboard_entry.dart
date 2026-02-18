import '../models/user.dart';

class LeaderboardEntry {
  final User user;
  final int score;
  final int tasksCompleted;
  int rank;

  LeaderboardEntry({
    required this.user,
    required this.score,
    required this.tasksCompleted,
    this.rank = 0,
  });
}
