class Notice {
  final String id;
  final String title;
  final String content;
  final String priority; // 'urgent', 'medium', 'normal'
  final String category;
  final DateTime createdAt;
  final String createdBy;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.createdBy,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      priority: json['priority'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'priority': priority,
      'category': category,
      'created_by': createdBy,
      // created_at is handled by default in DB
    };
  }
}
