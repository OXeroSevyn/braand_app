import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/leaderboard_entry.dart';
import '../models/achievement.dart';
import 'supabase_service.dart';

class GamificationService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Calculate leaderboard for a list of tasks and employees
  List<LeaderboardEntry> calculateLeaderboard(
      List<Task> tasks, List<User> employees) {
    Map<String, int> scores = {};
    Map<String, int> tasksCompleted = {};
    Map<String, int> moodPoints = {};
    Map<String, int> attendancePoints = {};

    // Initialize scores for all employees
    for (var emp in employees) {
      scores[emp.id] = 0;
      tasksCompleted[emp.id] = 0;
      moodPoints[emp.id] = 0;
      attendancePoints[emp.id] = 0;
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

    // Add points for mood tracking and attendance
    for (var emp in employees) {
      // Dummy logic for attendance points (e.g. 50 pts) and mood points (15 pts)
      attendancePoints[emp.id] = 50;
      moodPoints[emp.id] = 15;

      scores[emp.id] = (scores[emp.id] ?? 0) +
          (attendancePoints[emp.id] ?? 0) +
          (moodPoints[emp.id] ?? 0);
    }

    List<LeaderboardEntry> entries = [];
    for (var emp in employees) {
      entries.add(LeaderboardEntry(
        user: emp,
        score: scores[emp.id] ?? 0,
        tasksCompleted: tasksCompleted[emp.id] ?? 0,
        moodPoints: moodPoints[emp.id] ?? 0,
        attendancePoints: attendancePoints[emp.id] ?? 0,
      ));
    }

    entries.sort((a, b) => b.score.compareTo(a.score));

    for (int i = 0; i < entries.length; i++) {
      entries[i].rank = i + 1;
      // Simulate trend for now: 1st place is always UP, middle random, last DOWN
      if (i == 0)
        entries[i].trend = 'UP';
      else if (i == entries.length - 1)
        entries[i].trend = 'DOWN';
      else
        entries[i].trend = i % 2 == 0 ? 'UP' : 'STEADY';
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

  /// Get achievements for a user
  Future<List<Achievement>> getAchievements(String userId) async {
    // Simulated data for the demo
    return [
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Clock-in before 10:30 AM for 5 days',
        icon: '🌅',
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: '2026-02-20',
      ),
      Achievement(
        id: 'deep_diver',
        title: 'Deep Diver',
        description: 'Complete 3 High-Priority tasks in a day',
        icon: '🤿',
        isUnlocked: false,
        progress: 0.67,
      ),
      Achievement(
        id: 'vibe_master',
        title: 'Vibe Master',
        description: 'Consistently positive mood tracking',
        icon: '✨',
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: '2026-02-25',
      ),
      Achievement(
        id: 'task_titan',
        title: 'Task Titan',
        description: 'Complete 100 tasks in total',
        icon: '⚔️',
        isUnlocked: false,
        progress: 0.45,
      ),
    ];
  }

  /// Get available loot boxes for a user
  Future<int> getLootBoxCount(String userId) async {
    // For demo purposes, we'll say the user has 1 box if they have a streak > 5
    // Actually just return 1 for visual testing
    return 1;
  }
}
