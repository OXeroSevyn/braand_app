import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/device_binding.dart';
import 'supabase_service.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SupabaseService _supabase = SupabaseService();

  /// Get unique device ID
  Future<String> getDeviceId() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? 'web-client';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      } else {
        return 'unknown';
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return 'unknown';
    }
  }

  /// Get device information (name, model, etc.)
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'name': webInfo.browserName.name,
          'model': webInfo.platform ?? 'Web Browser',
          'os': 'Web',
        };
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'name': androidInfo.model,
          'model': '${androidInfo.manufacturer} ${androidInfo.model}',
          'os': 'Android ${androidInfo.version.release}',
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'name': iosInfo.name,
          'model': iosInfo.model,
          'os': 'iOS ${iosInfo.systemVersion}',
        };
      } else {
        return {
          'name': 'Unknown',
          'model': 'Unknown',
          'os': 'Unknown',
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {
        'name': 'Unknown',
        'model': 'Unknown',
        'os': 'Unknown',
      };
    }
  }

  /// Check if current device is registered for this user
  Future<bool> isDeviceRegistered(String userId) async {
    try {
      final deviceId = await getDeviceId();
      final binding = await _supabase.getDeviceBinding(userId, deviceId);
      return binding != null && binding.isActive;
    } catch (e) {
      debugPrint('Error checking device registration: $e');
      return false;
    }
  }

  /// Register current device for user
  Future<DeviceBinding?> registerDevice(String userId) async {
    try {
      final deviceId = await getDeviceId();
      final deviceInfo = await getDeviceInfo();

      return await _supabase.registerDevice(
        userId: userId,
        deviceId: deviceId,
        deviceName: deviceInfo['name']!,
        deviceModel: deviceInfo['model']!,
      );
    } catch (e) {
      debugPrint('Error registering device: $e');
      return null;
    }
  }

  /// Unregister a device
  Future<bool> unregisterDevice(String deviceId) async {
    try {
      await _supabase.unregisterDevice(deviceId);
      return true;
    } catch (e) {
      debugPrint('Error unregistering device: $e');
      return false;
    }
  }

  /// Update last used timestamp for device
  Future<void> updateDeviceLastUsed(String userId) async {
    try {
      final deviceId = await getDeviceId();
      await _supabase.updateDeviceLastUsed(userId, deviceId);
    } catch (e) {
      debugPrint('Error updating device last used: $e');
    }
  }

  /// Get all registered devices for a user
  Future<List<DeviceBinding>> getUserDevices(String userId) async {
    try {
      return await _supabase.getUserDevices(userId);
    } catch (e) {
      debugPrint('Error getting user devices: $e');
      return [];
    }
  }
}
