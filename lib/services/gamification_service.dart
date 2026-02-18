import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/leaderboard_entry.dart';
import 'supabase_service.dart';

class GamificationService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Calculate leaderboard for a list of tasks and employees
  List<LeaderboardEntry> calculateLeaderboard(
      List<Task> tasks, List<User> employees) {
    Map<String, int> scores = {};
    Map<String, int> tasksCompleted = {};

    // Initialize scores for all employees
    for (var emp in employees) {
      scores[emp.id] = 0;
      tasksCompleted[emp.id] = 0;
    }

    for (var task in tasks) {
      if (!scores.containsKey(task.userId)) continue;

      int points = 0;

      if (task.isCompleted) {
        points += 10;
        tasksCompleted[task.userId] = (tasksCompleted[task.userId] ?? 0) + 1;

        if (task.priority == 'urgent') {
          points += 10;
        }

        if (task.adminAssessment == 'accepted') {
          points += 30;
        } else if (task.adminAssessment == 'rejected') {
          points = -10;
        }
      }

      scores[task.userId] = (scores[task.userId] ?? 0) + points;
    }

    List<LeaderboardEntry> entries = [];
    for (var emp in employees) {
      entries.add(LeaderboardEntry(
        user: emp,
        score: scores[emp.id] ?? 0,
        tasksCompleted: tasksCompleted[emp.id] ?? 0,
      ));
    }

    entries.sort((a, b) => b.score.compareTo(a.score));

    for (int i = 0; i < entries.length; i++) {
      entries[i].rank = i + 1;
    }

    return entries;
  }

  /// Get today's high scorer
  Future<LeaderboardEntry?> getTodaysHighScorer() async {
    try {
      final employees = await _supabaseService.getAllEmployees();
      if (employees.isEmpty) return null;

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final tasks = await _supabaseService.getTasksForDateRange(start, end);

      final leaderboard = calculateLeaderboard(tasks, employees);

      if (leaderboard.isNotEmpty && leaderboard.first.score > 0) {
        return leaderboard.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting today\'s high scorer: $e');
      return null;
    }
  }
}
