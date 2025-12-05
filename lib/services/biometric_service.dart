// import 'package:local_auth/local_auth.dart';

class BiometricService {
  // final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> canUseBiometric() async {
    return false; // Disabled for web build fix
  }

  /// Get list of available biometric types on this device
  Future<List<String>> getAvailableBiometrics() async {
    return [];
  }

  /// Authenticate user with biometric
  /// Returns true if authentication successful
  Future<bool> authenticate(String reason) async {
    return false;
  }

  /// Get the type of biometric being used (for display purposes)
  Future<String> getBiometricType() async {
    return 'none';
  }

  /// Check if device is enrolled with biometrics
  Future<bool> isDeviceEnrolled() async {
    return false;
  }
}
