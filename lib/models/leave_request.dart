class LeaveRequest {
  final String id;
  final String userId;
  final String? userName; // For Admin view (joined query or separate fetch)
  final String? userRole; // For Admin view
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType;
  final String? reason;
  final String status;
  final String? adminComment;
  final DateTime createdAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    this.userName,
    this.userRole,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    this.reason,
    required this.status,
    this.adminComment,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    // Handle potential joined profiles data
    String? name;
    String? role;
    if (json['profiles'] != null) {
      name = json['profiles']['name'];
      role = json['profiles']['role'];
    } else {
      // Handle flat view structure (admin_leave_requests_view)
      name = json['user_name'];
      role = json['user_role'];
    }

    return LeaveRequest(
      id: json['id'],
      userId: json['user_id'],
      userName: name,
      userRole: role,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      leaveType: json['leave_type'],
      reason: json['reason'],
      status: json['status'] ?? 'Pending',
      adminComment: json['admin_comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'leave_type': leaveType,
      'reason': reason,
      'status': status,
      'admin_comment': adminComment,
    };
  }
}
