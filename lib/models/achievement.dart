class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final double progress;
  final String? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedDate,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      isUnlocked: json['is_unlocked'] ?? false,
      progress: (json['progress'] ?? 0.0).toDouble(),
      unlockedDate: json['unlocked_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'is_unlocked': isUnlocked,
      'progress': progress,
      'unlocked_date': unlockedDate,
    };
  }
}
