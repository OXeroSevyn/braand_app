import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/device_binding.dart';
import '../models/office_location.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Device Bindings ---

  Future<DeviceBinding?> getDeviceBinding(
      String userId, String deviceId) async {
    try {
      final response = await _supabase
          .from('device_bindings')
          .select()
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return DeviceBinding.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<DeviceBinding?> registerDevice({
    required String userId,
    required String deviceId,
    required String deviceName,
    required String deviceModel,
  }) async {
    try {
      final response = await _supabase
          .from('device_bindings')
          .insert({
            'user_id': userId,
            'device_id': deviceId,
            'device_name': deviceName,
            'device_model': deviceModel,
            'registered_at': DateTime.now().toIso8601String(),
            'is_active': true,
          })
          .select()
          .single();

      return DeviceBinding.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> unregisterDevice(String deviceId) async {
    await _supabase
        .from('device_bindings')
        .update({'is_active': false}).eq('device_id', deviceId);
  }

  Future<void> updateDeviceLastUsed(String userId, String deviceId) async {
    await _supabase
        .from('device_bindings')
        .update({'last_used_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .eq('device_id', deviceId);
  }

  Future<List<DeviceBinding>> getUserDevices(String userId) async {
    final response = await _supabase
        .from('device_bindings')
        .select()
        .eq('user_id', userId)
        .order('registered_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => DeviceBinding.fromJson(json)).toList();
  }

  // --- Office Locations ---

  Future<List<OfficeLocation>> getOfficeLocations() async {
    try {
      debugPrint('📍 Fetching office locations...');
      final response = await _supabase
          .from('office_locations')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      debugPrint('📍 Raw locations response: $response');
      final List<dynamic> data = response as List<dynamic>;
      final locations =
          data.map((json) => OfficeLocation.fromJson(json)).toList();
      debugPrint('✅ Parsed ${locations.length} active locations');
      return locations;
    } catch (e) {
      debugPrint('❌ Error fetching locations: $e');
      rethrow;
    }
  }

  Future<OfficeLocation?> createOfficeLocation({
    required String name,
    required double latitude,
    required double longitude,
    int radiusMeters = 100,
  }) async {
    try {
      debugPrint(
          '📍 Creating office location: $name at ($latitude, $longitude)');
      final response = await _supabase
          .from('office_locations')
          .insert({
            'name': name,
            'latitude': latitude,
            'longitude': longitude,
            'radius_meters': radiusMeters,
            'is_active': true,
          })
          .select()
          .single();

      debugPrint('✅ Office location created successfully');
      return OfficeLocation.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating office location: $e');
      rethrow;
    }
  }

  Future<void> updateOfficeLocation(
      String id, Map<String, dynamic> updates) async {
    await _supabase.from('office_locations').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', id);
  }

  Future<void> deleteOfficeLocation(String id) async {
    await _supabase.from('office_locations').delete().eq('id', id);
  }

  // --- Office Hours Settings ---

  /// Get the active office hours settings
  Future<Map<String, dynamic>?> getOfficeHours() async {
    try {
      final response = await _supabase
          .from('office_hours_settings')
          .select()
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('❌ Error getting office hours: $e');
      return null;
    }
  }

  /// Update office hours settings
  Future<void> updateOfficeHours({
    required TimeOfDay inTime,
    required TimeOfDay outTime,
    bool sundayOff = true,
  }) async {
    try {
      // Deactivate all existing settings
      await _supabase
          .from('office_hours_settings')
          .update({'is_active': false}).neq(
              'id', '00000000-0000-0000-0000-000000000000');

      // Insert new settings
      await _supabase.from('office_hours_settings').insert({
        'in_time':
            '${inTime.hour.toString().padLeft(2, '0')}:${inTime.minute.toString().padLeft(2, '0')}:00',
        'out_time':
            '${outTime.hour.toString().padLeft(2, '0')}:${outTime.minute.toString().padLeft(2, '0')}:00',
        'sunday_off': sundayOff,
        'is_active': true,
      });

      debugPrint('✅ Office hours updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating office hours: $e');
      rethrow;
    }
  }

  // --- Premium Features ---

  /// Calculate the current attendance streak for a user
  Future<int> calculateStreak(String userId) async {
    try {
      final response = await _supabase
          .from('attendance_records')
          .select('timestamp, type')
          .eq('user_id', userId)
          .eq('type', 'AttendanceType.CLOCK_IN')
          .order('timestamp', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return 0;

      final List<DateTime> dates = data.map((json) {
        final dt = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
        return DateTime(dt.year, dt.month, dt.day);
      }).toList();

      // Remove duplicates (multiple clock-ins on same day)
      final uniqueDates = dates.toSet().toList();
      uniqueDates.sort((a, b) => b.compareTo(a));

      DateTime today = DateTime.now();
      DateTime checkDate = DateTime(today.year, today.month, today.day);

      // If the latest record is not today or yesterday, streak is broken
      if (uniqueDates.first
          .isBefore(checkDate.subtract(const Duration(days: 1)))) {
        return 0;
      }

      // Simple streak logic
      int streak = 1;
      for (int i = 1; i < uniqueDates.length; i++) {
        if (uniqueDates[i - 1].difference(uniqueDates[i]).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating streak: $e');
      return 0;
    }
  }

  // --- Milestone Celebration Bot ---

  Future<void> checkAndBroadcastMilestones({
    required Future<void> Function(
            {required String title, required String message})
        broadcastFn,
  }) async {
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final profilesResponse = await _supabase.from('profiles').select();
      final List<dynamic> profiles = profilesResponse as List<dynamic>;

      for (var profile in profiles) {
        final birthday = profile['birthday'] as String?;
        final joiningDate = profile['joining_date'] as String?;
        final name = profile['name'] ?? 'Team Member';

        if (birthday != null && birthday.contains(todayStr)) {
          await broadcastFn(
            title: '🎂 Happy Birthday!',
            message: 'Wishing $name a fantastic birthday today! 🎈',
          );
        }

        if (joiningDate != null && joiningDate.contains(todayStr)) {
          final joinYear = DateTime.parse(joiningDate).year;
          final years = now.year - joinYear;
          if (years > 0) {
            await broadcastFn(
              title: '🎊 Work Anniversary!',
              message:
                  'Congratulations to $name on completing $years ${years == 1 ? 'year' : 'years'} with the team! 🚀',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking milestones: $e');
    }
  }
}
