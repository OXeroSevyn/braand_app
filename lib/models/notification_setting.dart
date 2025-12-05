class NotificationSetting {
  final String id;
  final String type; // 'clock_in', 'clock_out', 'break_reminder'
  final bool enabled;
  final String time; // Format: "HH:mm"
  final String message;
  final List<String> daysOfWeek; // ['mon', 'tue', 'wed', 'thu', 'fri']
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSetting({
    required this.id,
    required this.type,
    required this.enabled,
    required this.time,
    required this.message,
    required this.daysOfWeek,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    return NotificationSetting(
      id: json['id'] as String,
      type: json['type'] as String,
      enabled: json['enabled'] as bool,
      time: json['time'] as String,
      message: json['message'] as String,
      daysOfWeek: (json['days_of_week'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'enabled': enabled,
      'time': time,
      'message': message,
      'days_of_week': daysOfWeek,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationSetting copyWith({
    String? id,
    String? type,
    bool? enabled,
    String? time,
    String? message,
    List<String>? daysOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      message: message ?? this.message,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to get display name
  String get displayName {
    switch (type) {
      case 'clock_in':
        return 'Clock In Reminder';
      case 'clock_out':
        return 'Clock Out Reminder';
      case 'break_reminder':
        return 'Break Reminder';
      case 'custom_message':
        return 'Custom Message';
      default:
        return type;
    }
  }

  // Helper to check if notification should trigger today
  bool shouldTriggerToday() {
    if (!enabled) return false;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    return daysOfWeek.contains(dayName);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'mon';
      case 2:
        return 'tue';
      case 3:
        return 'wed';
      case 4:
        return 'thu';
      case 5:
        return 'fri';
      case 6:
        return 'sat';
      case 7:
        return 'sun';
      default:
        return '';
    }
  }
}
