class LeaveBalance {
  final String id;
  final String userId;
  final int year;
  final int totalLeaves;
  final int usedLeaves;
  final int pendingLeaves;

  LeaveBalance({
    required this.id,
    required this.userId,
    required this.year,
    this.totalLeaves = 12,
    this.usedLeaves = 0,
    this.pendingLeaves = 0,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'],
      userId: json['user_id'],
      year: json['year'],
      totalLeaves: json['total_leaves'] ?? 12,
      usedLeaves: json['used_leaves'] ?? 0,
      pendingLeaves: json['pending_leaves'] ?? 0,
    );
  }

  int get remaining => totalLeaves - usedLeaves;
}
