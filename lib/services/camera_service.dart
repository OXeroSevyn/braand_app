import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class CameraService {
  final SupabaseService _supabase = SupabaseService();
  List<CameraDescription> _cameras = [];

  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  CameraDescription? getFrontCamera() {
    if (_cameras.isEmpty) return null;
    try {
      return _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> takeSelfie(CameraController controller) async {
    try {
      if (!controller.value.isInitialized) {
        return null;
      }
      final XFile file = await controller.takePicture();
      return file;
    } catch (e) {
      debugPrint('Error taking selfie: $e');
      return null;
    }
  }

  Future<String?> uploadPhoto(XFile photo, String userId) async {
    try {
      final Uint8List bytes = await photo.readAsBytes();
      final String fileName =
          'attendance_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      return await _supabase.uploadAttendancePhoto(bytes, fileName);
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }
}
