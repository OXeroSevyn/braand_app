import 'package:flutter/material.dart';
import 'user.dart';

class Task {
  final String id;
  final String userId;
  final DateTime date; // Logical task date (no time component)
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  Task({
    required this.id,
    required this.userId,
    required this.date,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    this.startTime,
    this.endTime,
  });

  /// Calculate duration in hours (returns null if times are not set)
  double? get durationInHours {
    if (startTime == null || endTime == null) return null;
    
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    
    // Handle case where end time is next day
    int diffMinutes = endMinutes - startMinutes;
    if (diffMinutes < 0) {
      diffMinutes += 24 * 60; // Add 24 hours
    }
    
    return diffMinutes / 60.0;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        return null;
      }
      return null;
    }

    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['task_date'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      startTime: parseTime(json['start_time'] as String?),
      endTime: parseTime(json['end_time'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'user_id': userId,
      'task_date': DateTime.utc(date.year, date.month, date.day).toIso8601String(),
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
    };
  }
}


