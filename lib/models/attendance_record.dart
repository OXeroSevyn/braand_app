enum AttendanceType { CLOCK_IN, CLOCK_OUT, BREAK_START, BREAK_END }

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(lat: json['lat'], lng: json['lng']);
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}

class AttendanceRecord {
  final String id;
  final String userId;
  final int timestamp;
  final AttendanceType type;
  final Location? location;
  final String? deviceId;
  final bool biometricVerified;
  final String? photoUrl;
  final String? verificationMethod; // 'fingerprint', 'face_id', or 'none'

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    this.location,
    this.deviceId,
    this.biometricVerified = false,
    this.photoUrl,
    this.verificationMethod,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      userId: json['userId'],
      timestamp: json['timestamp'],
      type: AttendanceType.values.firstWhere(
        (e) => e.toString() == 'AttendanceType.${json['type']}',
      ),
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      deviceId: json['device_id'],
      biometricVerified: json['biometric_verified'] ?? false,
      photoUrl: json['photo_url'],
      verificationMethod: json['verification_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp,
      'type': type.toString().split('.').last,
      'location': location?.toJson(),
      'device_id': deviceId,
      'biometric_verified': biometricVerified,
      'photo_url': photoUrl,
      'verification_method': verificationMethod,
    };
  }
}
