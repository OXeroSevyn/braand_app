import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  /// Create a new task for a user
  Future<void> createTask(Task task) async {
    await _supabase.from('tasks').insert({
      'user_id': task.userId,
      'task_date': DateTime.utc(task.date.year, task.date.month, task.date.day)
          .toIso8601String(),
      'title': task.title,
      'description': task.description,
      'is_completed': task.isCompleted,
      'start_time': _formatTime(task.startTime),
      'end_time': _formatTime(task.endTime),
      'actual_end_time': _formatTime(task.actualEndTime),
      'admin_assessment': task.adminAssessment,
      'priority': task.priority,
    });
  }

  /// Get tasks for a user on a specific date
  Future<List<Task>> getUserTasksForDate(String userId, DateTime date) async {
    final start = DateTime.utc(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .gte('task_date', start.toIso8601String())
        .lt('task_date', end.toIso8601String())
        .order('created_at', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Update the completion status of a task
  Future<void> updateTaskStatus(String taskId, bool isCompleted,
      {TimeOfDay? actualEndTime}) async {
    await _supabase.from('tasks').update({
      'is_completed': isCompleted,
      'actual_end_time': isCompleted ? _formatTime(actualEndTime) : null,
    }).eq('id', taskId);
  }

  /// Update the Admin Assessment of a task
  Future<void> updateTaskAssessment(String taskId, String assessment) async {
    try {
      await _supabase.from('tasks').update({
        'admin_assessment': assessment,
      }).eq('id', taskId);
      debugPrint('✅ Task assessment updated (Trigger will handle points)');
    } catch (e) {
      debugPrint('❌ Error updating task assessment: $e');
      rethrow;
    }
  }

  /// Update the Priority of a task
  Future<void> updateTaskPriority(String taskId, String priority) async {
    await _supabase.from('tasks').update({
      'priority': priority,
    }).eq('id', taskId);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  /// Get tasks for all employees within a date range (for admin reports)
  Future<List<Task>> getTasksForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .gte('task_date',
            DateTime.utc(start.year, start.month, start.day).toIso8601String())
        .lte(
            'task_date',
            DateTime.utc(end.year, end.month, end.day, 23, 59, 59)
                .toIso8601String())
        .order('task_date', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // --- Monthly & Daily Tasks (Admin Managed) ---

  /// Create a new monthly task (Admin only)
  Future<void> createMonthlyTask({
    required String title,
    String? description,
    required int month,
    required int year,
    String? assignedTo,
    bool isPrivate = false,
    String priority = 'Medium',
  }) async {
    try {
      await _supabase.from('monthly_tasks').insert({
        'title': title,
        'description': description,
        'task_type': 'monthly',
        'month': month,
        'year': year,
        'assigned_to': assignedTo,
        'is_private': isPrivate,
        'created_by': _supabase.auth.currentUser?.id,
        'priority': priority,
      });
      debugPrint('✅ Monthly task created successfully');
    } catch (e) {
      debugPrint('❌ Error creating monthly task: $e');
      rethrow;
    }
  }

  /// Create a new date-specific task (Admin only)
  Future<void> createDailyTask({
    required String title,
    String? description,
    required DateTime specificDate,
    int? timeLimitValue,
    String? timeUnit,
    String? assignedTo,
    bool isPrivate = false,
    String priority = 'Medium',
  }) async {
    try {
      // Convert time limit to minutes
      int? timeLimitMinutes;
      DateTime? deadlineTime;

      if (timeLimitValue != null && timeUnit != null) {
        switch (timeUnit) {
          case 'minutes':
            timeLimitMinutes = timeLimitValue;
            break;
          case 'hours':
            timeLimitMinutes = timeLimitValue * 60;
            break;
          case 'days':
            timeLimitMinutes = timeLimitValue * 60 * 24;
            break;
        }
        deadlineTime = specificDate.add(Duration(minutes: timeLimitMinutes!));
      }

      await _supabase.from('monthly_tasks').insert({
        'title': title,
        'description': description,
        'task_type': 'daily',
        'specific_date': specificDate.toIso8601String().split('T')[0],
        'time_limit_minutes': timeLimitMinutes,
        'time_unit': timeUnit,
        'deadline_time': deadlineTime?.toIso8601String(),
        'assigned_to': assignedTo,
        'is_private': isPrivate,
        'priority': priority,
        'created_by': _supabase.auth.currentUser?.id,
      });
      debugPrint('✅ Daily task created successfully');
    } catch (e) {
      debugPrint('❌ Error creating daily task: $e');
      rethrow;
    }
  }

  /// Get all monthly tasks for a specific month/year
  Future<List<Map<String, dynamic>>> getMonthlyTasks({
    required int month,
    required int year,
    String? userId,
  }) async {
    try {
      if (userId != null) {
        final response = await _supabase
            .from('monthly_tasks')
            .select('''
              *,
              user_monthly_tasks!left(is_completed, completed_at, started_at)
            ''')
            .eq('task_type', 'monthly')
            .eq('month', month)
            .eq('year', year)
            .eq('user_monthly_tasks.user_id', userId)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      } else {
        final response = await _supabase
            .from('monthly_tasks')
            .select()
            .eq('task_type', 'monthly')
            .eq('month', month)
            .eq('year', year)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      }
    } catch (e) {
      debugPrint('❌ Error fetching monthly tasks: $e');
      return [];
    }
  }

  /// Get all date-specific tasks for a specific date
  Future<List<Map<String, dynamic>>> getDailyTasks({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      if (userId != null) {
        final response = await _supabase
            .from('monthly_tasks')
            .select('''
              *,
              user_monthly_tasks!left(is_completed, completed_at, started_at)
            ''')
            .eq('task_type', 'daily')
            .eq('specific_date', dateStr)
            .eq('user_monthly_tasks.user_id', userId)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      } else {
        final response = await _supabase
            .from('monthly_tasks')
            .select()
            .eq('task_type', 'daily')
            .eq('specific_date', dateStr)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      }
    } catch (e) {
      debugPrint('❌ Error fetching daily tasks: $e');
      return [];
    }
  }

  /// Update monthly task status and sync is_completed
  Future<void> updateMonthlyTaskStatus({
    required String taskId,
    required String userId,
    required String status,
  }) async {
    try {
      final isCompleted = status == 'Completed';
      final now = DateTime.now().toIso8601String();

      final existing = await _supabase
          .from('user_monthly_tasks')
          .select()
          .eq('user_id', userId)
          .eq('task_id', taskId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('user_monthly_tasks').insert({
          'user_id': userId,
          'task_id': taskId,
          'status': status,
          'is_completed': isCompleted,
          'completed_at': isCompleted ? now : null,
          'started_at': now,
        });
      } else {
        await _supabase
            .from('user_monthly_tasks')
            .update({
              'status': status,
              'is_completed': isCompleted,
              'completed_at': isCompleted ? now : null,
            })
            .eq('user_id', userId)
            .eq('task_id', taskId);
      }
    } catch (e) {
      debugPrint('❌ Error updating task status: $e');
      rethrow;
    }
  }

  /// Mark task as started (for progress tracking)
  Future<void> startTask({
    required String taskId,
    required String userId,
  }) async {
    try {
      final existing = await _supabase
          .from('user_monthly_tasks')
          .select()
          .eq('user_id', userId)
          .eq('task_id', taskId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('user_monthly_tasks').insert({
          'user_id': userId,
          'task_id': taskId,
          'is_completed': false,
          'started_at': DateTime.now().toIso8601String(),
        });
      } else if (existing['started_at'] == null) {
        await _supabase
            .from('user_monthly_tasks')
            .update({
              'started_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('task_id', taskId);
      }
      debugPrint('✅ Task started');
    } catch (e) {
      debugPrint('❌ Error starting task: $e');
      rethrow;
    }
  }

  /// Delete a monthly task (Admin only)
  Future<void> deleteMonthlyTask(String taskId) async {
    try {
      await _supabase.from('monthly_tasks').delete().eq('id', taskId);
      debugPrint('✅ Monthly task deleted');
    } catch (e) {
      debugPrint('❌ Error deleting monthly task: $e');
      rethrow;
    }
  }
}
