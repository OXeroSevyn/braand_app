class AppVersion {
  final String id;
  final int versionCode;
  final String versionName; // e.g., "1.0.0"
  final String apkUrl;
  final String? releaseNotes;
  final bool forceUpdate;
  final DateTime createdAt;

  AppVersion({
    required this.id,
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.releaseNotes,
    this.forceUpdate = false,
    required this.createdAt,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: json['id'],
      versionCode: json['version_code'],
      versionName: json['version_name'],
      apkUrl: json['apk_url'],
      releaseNotes: json['release_notes'],
      forceUpdate: json['force_update'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
