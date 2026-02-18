class MonthlyTask {
  final String id;
  final String title;
  final String? description;
  final String taskType; // 'monthly' or 'daily'
  final int? month;
  final int? year;
  final DateTime? specificDate;
  final int? timeLimitHours; // Deprecated
  final int? timeLimitMinutes; // Actual time limit
  final String? timeUnit; // 'minutes', 'hours', 'days'
  final DateTime? deadlineTime;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? startedAt;
  final String? assignedTo; // UUID of assigned employee
  final bool isPrivate; // Only visible to admins
  final String priority; // Low, Medium, High, Urgent
  final String status; // Pending, In Progress, Completed, On Hold, Review

  MonthlyTask({
    required this.id,
    required this.title,
    this.description,
    required this.taskType,
    this.month,
    this.year,
    this.specificDate,
    this.timeLimitHours,
    this.timeLimitMinutes,
    this.timeUnit,
    this.deadlineTime,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.startedAt,
    this.assignedTo,
    this.isPrivate = false,
    this.priority = 'Medium',
    this.status = 'Pending',
  });

  // Calculate progress percentage for time-limited tasks
  double get progressPercentage {
    // If no time limit, return 0
    final timeLimit = timeLimitMinutes ??
        (timeLimitHours != null ? timeLimitHours! * 60 : null);
    if (timeLimit == null || deadlineTime == null || specificDate == null) {
      return 0.0;
    }

    // If completed, return 100%
    if (isCompleted && completedAt != null) {
      return 100.0;
    }

    final now = DateTime.now();

    // If deadline has passed, return 100%
    if (now.isAfter(deadlineTime!)) {
      return 100.0;
    }

    // If task hasn't started yet, return 0%
    if (now.isBefore(specificDate!)) {
      return 0.0;
    }

    // Calculate elapsed time vs total time
    final totalDuration = deadlineTime!.difference(specificDate!);
    final elapsed = now.difference(specificDate!);

    if (totalDuration.inMilliseconds == 0) return 100.0;

    return (elapsed.inMilliseconds / totalDuration.inMilliseconds * 100)
        .clamp(0.0, 100.0);
  }

  // Check if task is overdue
  bool get isOverdue {
    if (isCompleted || deadlineTime == null) return false;
    return DateTime.now().isAfter(deadlineTime!);
  }

  // Get time remaining text
  String get timeRemainingText {
    if (isCompleted) return 'Completed';
    if (deadlineTime == null) return 'No deadline';

    final now = DateTime.now();
    if (now.isAfter(deadlineTime!)) return 'Overdue';

    final remaining = deadlineTime!.difference(now);
    if (remaining.inHours > 24) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h remaining';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
    } else {
      return '${remaining.inMinutes}m remaining';
    }
  }

  // Get formatted time limit for display
  String get formattedTimeLimit {
    if (timeLimitMinutes == null || timeUnit == null) return '';

    switch (timeUnit) {
      case 'minutes':
        return '$timeLimitMinutes minutes';
      case 'hours':
        final hours = timeLimitMinutes! ~/ 60;
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      case 'days':
        final days = timeLimitMinutes! ~/ (60 * 24);
        return '$days ${days == 1 ? 'day' : 'days'}';
      default:
        return '$timeLimitMinutes minutes';
    }
  }

  factory MonthlyTask.fromJson(Map<String, dynamic> json) {
    // Handle user_monthly_tasks join data
    final userTaskData = json['user_monthly_tasks'];
    final isCompleted = userTaskData != null &&
        userTaskData is List &&
        userTaskData.isNotEmpty &&
        (userTaskData[0]['is_completed'] ?? false);
    final completedAt = userTaskData != null &&
            userTaskData is List &&
            userTaskData.isNotEmpty &&
            userTaskData[0]['completed_at'] != null
        ? DateTime.parse(userTaskData[0]['completed_at'])
        : null;
    final startedAt = userTaskData != null &&
            userTaskData is List &&
            userTaskData.isNotEmpty &&
            userTaskData[0]['started_at'] != null
        ? DateTime.parse(userTaskData[0]['started_at'])
        : null;

    return MonthlyTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      taskType: json['task_type'] ?? 'monthly',
      month: json['month'],
      year: json['year'],
      specificDate: json['specific_date'] != null
          ? DateTime.parse(json['specific_date'])
          : null,
      timeLimitHours: json['time_limit_hours'],
      timeLimitMinutes: json['time_limit_minutes'],
      timeUnit: json['time_unit'],
      deadlineTime: json['deadline_time'] != null
          ? DateTime.parse(json['deadline_time'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      isCompleted: isCompleted,
      completedAt: completedAt,
      startedAt: startedAt,
      assignedTo: json['assigned_to'],
      isPrivate: json['is_private'] ?? false,
      priority: json['priority'] ?? 'Medium',
      // Map status from joined user_monthly_tasks if available
      status: (json['user_monthly_tasks'] != null &&
              (json['user_monthly_tasks'] as List).isNotEmpty)
          ? json['user_monthly_tasks'][0]['status'] ?? 'Pending'
          : 'Pending',
    );
  }
}
