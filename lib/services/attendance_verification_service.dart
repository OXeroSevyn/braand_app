import 'package:flutter/foundation.dart';
import 'biometric_service.dart';
import 'device_service.dart';
import 'location_service.dart';
import 'camera_service.dart';
import 'supabase_service.dart';
import '../models/attendance_record.dart';

/// Result of verification process
class VerificationResult {
  final bool success;
  final String? errorMessage;
  final String? deviceId;
  final String? verificationMethod;
  final String? photoUrl;
  final bool biometricVerified;
  final bool locationVerified;
  final bool deviceVerified;

  VerificationResult({
    required this.success,
    this.errorMessage,
    this.deviceId,
    this.verificationMethod,
    this.photoUrl,
    this.biometricVerified = false,
    this.locationVerified = false,
    this.deviceVerified = false,
  });
}

/// Coordinates all verification steps for attendance
class AttendanceVerificationService {
  final BiometricService _biometricService = BiometricService();
  final DeviceService _deviceService = DeviceService();
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();
  final SupabaseService _supabaseService = SupabaseService();

  /// Perform complete verification for clock-in/out
  Future<VerificationResult> verifyAttendance({
    required String userId,
    required AttendanceType type,
    bool requirePhoto = false,
  }) async {
    try {
      // Step 1: Device Verification
      debugPrint('🔐 Step 1: Verifying device...');
      final deviceId = await _deviceService.getDeviceId();
      final isDeviceRegistered =
          await _deviceService.isDeviceRegistered(userId);

      if (!isDeviceRegistered) {
        debugPrint('❌ Device not registered');
        return VerificationResult(
          success: false,
          errorMessage:
              'Device not registered. Please register this device first.',
          deviceId: deviceId,
        );
      }
      debugPrint('✅ Device verified: $deviceId');

      // Step 2: Biometric Verification (OPTIONAL - won't block if it fails)
      debugPrint('🔐 Step 2: Attempting biometric authentication...');

      bool biometricVerified = false;
      String? verificationMethod;

      try {
        final canUseBiometric = await _biometricService.canUseBiometric();
        if (canUseBiometric) {
          final biometricAvailable = await _biometricService.isDeviceEnrolled();

          if (biometricAvailable) {
            final availableBiometrics =
                await _biometricService.getAvailableBiometrics();
            debugPrint('📱 Available biometrics: $availableBiometrics');

            final biometricSuccess = await _biometricService.authenticate(
              'Verify your identity to ${type == AttendanceType.CLOCK_IN ? 'clock in' : 'clock out'}',
            );

            if (biometricSuccess) {
              biometricVerified = true;
              verificationMethod = await _biometricService.getBiometricType();
              debugPrint('✅ Biometric verified: $verificationMethod');
            } else {
              debugPrint(
                  '⚠️ Biometric authentication failed - continuing without it');
            }
          } else {
            debugPrint('⚠️ No biometric enrolled - continuing without it');
          }
        } else {
          debugPrint(
              '⚠️ Biometric hardware not available - continuing without it');
        }
      } catch (e) {
        debugPrint('⚠️ Biometric error: $e - continuing without it');
      }

      // Step 3: Location Verification
      debugPrint('🔐 Step 3: Verifying location...');
      final isWithinOffice = await _locationService.isWithinOfficeRadius();

      if (!isWithinOffice) {
        debugPrint('❌ Location verification failed');
        return VerificationResult(
          success: false,
          errorMessage:
              'You are not within the office radius. Please move closer to the office.',
          deviceId: deviceId,
          verificationMethod: verificationMethod,
          biometricVerified: biometricVerified,
          deviceVerified: true,
        );
      }
      debugPrint('✅ Location verified');

      // Step 4: Photo Capture (optional)
      String? photoUrl;
      if (requirePhoto) {
        debugPrint('🔐 Step 4: Photo capture required (skipping for now)');
        // Photo capture will be handled by UI
      }

      // Update device last used
      await _deviceService.updateDeviceLastUsed(userId);

      debugPrint('✅ All verifications passed!');
      return VerificationResult(
        success: true,
        deviceId: deviceId,
        verificationMethod: verificationMethod,
        photoUrl: photoUrl,
        biometricVerified: biometricVerified,
        locationVerified: true,
        deviceVerified: true,
      );
    } catch (e) {
      debugPrint('❌ Verification error: $e');
      return VerificationResult(
        success: false,
        errorMessage: 'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Register current device for user
  Future<bool> registerCurrentDevice(String userId) async {
    try {
      final binding = await _deviceService.registerDevice(userId);
      return binding != null;
    } catch (e) {
      debugPrint('Error registering device: $e');
      return false;
    }
  }

  /// Check if current device is registered
  Future<bool> isCurrentDeviceRegistered(String userId) async {
    return await _deviceService.isDeviceRegistered(userId);
  }

  /// Get current device ID
  Future<String> getCurrentDeviceId() async {
    return await _deviceService.getDeviceId();
  }
}
