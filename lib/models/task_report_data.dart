import 'task.dart';
import 'user.dart';

class TaskReportData {
  final User user;
  final List<Task> tasks;

  TaskReportData({required this.user, required this.tasks});

  int get totalTasks => tasks.length;

  int get completedTasks =>
      tasks.where((task) => task.isCompleted).length;

  /// Calculate total hours from all tasks that have both start and end times
  double get totalHours {
    double total = 0.0;
    for (final task in tasks) {
      if (task.durationInHours != null) {
        total += task.durationInHours!;
      }
    }
    return total;
  }
}


