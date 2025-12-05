import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionsService {
  /// Request all required permissions on first launch.
  /// Returns true if all essential permissions are granted.
  static Future<bool> requestAll() async {
    // Define the list of permissions we need.
    final List<Permission> permissions = [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.notification,
      // Biometric hardware on Android is covered by sensors permission.
      // Permission.sensors,
    ];

    bool allGranted = true;
    for (final perm in permissions) {
      final status = await perm.status;
      if (status.isDenied ||
          status.isRestricted ||
          status.isPermanentlyDenied) {
        final result = await perm.request();
        if (!result.isGranted) {
          debugPrint('⚠️ Permission ${perm.value} not granted.');
          allGranted = false;
        } else {
          debugPrint('✅ Permission ${perm.value} granted.');
        }
      } else if (status.isGranted) {
        debugPrint('✅ Permission ${perm.value} already granted.');
      }
    }
    return allGranted;
  }
}
