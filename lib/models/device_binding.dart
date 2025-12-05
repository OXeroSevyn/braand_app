class DeviceBinding {
  final String id;
  final String userId;
  final String deviceId;
  final String? deviceName;
  final String? deviceModel;
  final DateTime registeredAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  DeviceBinding({
    required this.id,
    required this.userId,
    required this.deviceId,
    this.deviceName,
    this.deviceModel,
    required this.registeredAt,
    this.lastUsedAt,
    required this.isActive,
  });

  factory DeviceBinding.fromJson(Map<String, dynamic> json) {
    return DeviceBinding(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceModel: json['device_model'],
      registeredAt: DateTime.parse(json['registered_at']),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_model': deviceModel,
      'registered_at': registeredAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
