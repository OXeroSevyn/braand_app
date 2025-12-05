class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'Admin' | 'Employee'
  final String department;
  final String? avatar;
  final String? bio;
  final String? phone;
  final String status; // 'pending' | 'active' | 'rejected'

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.avatar,
    this.bio,
    this.phone,
    this.status = 'pending',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      department: json['department'],
      avatar: json['avatar'] ?? json['avatar_url'],
      bio: json['bio'],
      phone: json['phone'],
      status: json['status'] ?? 'pending',
    );
  }

  // Factory to create User from Supabase User
  factory User.fromSupabase(Map<String, dynamic> data) {
    final metadata = data['user_metadata'] ?? {};
    return User(
      id: data['id'],
      name: metadata['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      role: metadata['role'] ?? 'Employee',
      department: metadata['department'] ?? 'General',
      avatar: metadata['avatar'],
      bio: metadata['bio'],
      phone: metadata['phone'],
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'avatar': avatar,
      'bio': bio,
      'phone': phone,
      'status': status,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
    String? avatar,
    String? bio,
    String? phone,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
