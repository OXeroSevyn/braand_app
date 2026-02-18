import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/office_location.dart';
import 'supabase_service.dart';
import 'dart:math' show cos, sqrt, asin;

class LocationService {
  final SupabaseService _supabase = SupabaseService();

  // Cache
  List<OfficeLocation>? _cachedOffices;
  DateTime? _lastOfficeFetchTime;
  static const Duration _cacheDuration =
      Duration(hours: 1); // Offices rarely change

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current device location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check permission first without requesting (faster)
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      // Try last known position first to speed up
      final lastPosition = await Geolocator.getLastKnownPosition();
      final now = DateTime.now();

      // If last known position is recent (e.g. < 2 mins), use it
      if (lastPosition != null &&
          now.difference(lastPosition.timestamp).inMinutes < 2) {
        return lastPosition;
      }

      // Otherwise get fresh position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get all active office locations
  Future<List<OfficeLocation>> getOfficeLocations(
      {bool forceRefresh = false}) async {
    try {
      final now = DateTime.now();

      if (!forceRefresh &&
          _cachedOffices != null &&
          _lastOfficeFetchTime != null &&
          now.difference(_lastOfficeFetchTime!) < _cacheDuration) {
        return _cachedOffices!;
      }

      final offices = await _supabase.getOfficeLocations();
      _cachedOffices = offices;
      _lastOfficeFetchTime = now;
      return offices;
    } catch (e) {
      debugPrint('Error getting office locations: $e');
      return _cachedOffices ?? []; // Return cache on error if available
    }
  }

  /// Check if current location is within any office radius
  Future<bool> isWithinOfficeRadius() async {
    try {
      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) return false;

      final offices = await getOfficeLocations();
      if (offices.isEmpty) {
        debugPrint('No office locations configured');
        return true; // Allow if no offices configured
      }

      for (final office in offices) {
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          office.latitude,
          office.longitude,
        );

        debugPrint(
            'Distance to ${office.name}: ${distance.toStringAsFixed(2)}m (radius: ${office.radiusMeters}m)');

        if (distance <= office.radiusMeters) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking office radius: $e');
      return false;
    }
  }

  /// Calculate distance between two coordinates in meters
  /// Uses Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  double sin(double radians) {
    return radians -
        (radians * radians * radians) / 6 +
        (radians * radians * radians * radians * radians) / 120;
  }

  /// Get nearest office location
  Future<OfficeLocation?> getNearestOffice() async {
    try {
      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) return null;

      final offices = await getOfficeLocations();
      if (offices.isEmpty) return null;

      OfficeLocation? nearest;
      double minDistance = double.infinity;

      for (final office in offices) {
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          office.latitude,
          office.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = office;
        }
      }

      return nearest;
    } catch (e) {
      debugPrint('Error getting nearest office: $e');
      return null;
    }
  }

  /// Stream of location status updates
  Stream<LocationStatus> getLocationStatusStream() async* {
    // Initial check
    yield await _checkStatus();

    // Listen to position updates
    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );

    await for (final position in positionStream) {
      yield await _checkStatus(position);
    }
  }

  Future<LocationStatus> _checkStatus([Position? currentPosition]) async {
    try {
      currentPosition ??= await getCurrentLocation();
      if (currentPosition == null) {
        return LocationStatus(
          isInRange: false,
          distanceToNearest: 0,
          message: 'Location unavailable',
        );
      }

      final offices = await getOfficeLocations();
      if (offices.isEmpty) {
        return LocationStatus(
          isInRange: true,
          distanceToNearest: 0,
          message: 'No office locations configured',
        );
      }

      OfficeLocation? nearest;
      double minDistance = double.infinity;

      for (final office in offices) {
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          office.latitude,
          office.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = office;
        }
      }

      if (nearest != null) {
        final isInRange = minDistance <= nearest.radiusMeters;
        return LocationStatus(
          isInRange: isInRange,
          distanceToNearest: minDistance,
          nearestOfficeName: nearest.name,
          message: isInRange
              ? 'You are at ${nearest.name}'
              : 'You are ${minDistance.toInt()}m away from ${nearest.name}',
        );
      }

      return LocationStatus(
        isInRange: false,
        distanceToNearest: 0,
        message: 'No office found',
      );
    } catch (e) {
      return LocationStatus(
        isInRange: false,
        distanceToNearest: 0,
        message: 'Error checking location',
      );
    }
  }
}

class LocationStatus {
  final bool isInRange;
  final double distanceToNearest;
  final String? nearestOfficeName;
  final String message;

  LocationStatus({
    required this.isInRange,
    required this.distanceToNearest,
    this.nearestOfficeName,
    required this.message,
  });
}
