import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../models/attendance_record.dart';
import '../models/report_data.dart';
import '../models/task.dart';
import '../models/device_binding.dart';
import '../models/office_location.dart';
import '../models/notice.dart';
import '../models/leave_request.dart';
import '../models/app_version.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Profiles ---

  Future<void> createProfile(app_models.User user) async {
    await _supabase.from('profiles').insert({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'department': user.department,
      'avatar': user.avatar,
      'status': 'pending', // Default status for new signups
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('📧 Sending password reset email to: $email');
      final redirectUrl =
          kIsWeb ? null : 'io.supabase.braandapp://login-callback';

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
      debugPrint('✅ Password reset email sent (Redirect: $redirectUrl)');
    } catch (e) {
      debugPrint('❌ Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('🔐 Updating password...');
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('✅ Password updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }

  Future<List<app_models.User>> getAllEmployees() async {
    debugPrint('📡 Fetching all active employees...');
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'Employee')
        .eq('status', 'active'); // Only fetch active employees

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} active employees from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  Future<List<app_models.User>> getAllAdmins() async {
    debugPrint('📡 Fetching all admins...');
    final response =
        await _supabase.from('profiles').select().eq('role', 'Admin');

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} admins from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  Future<List<app_models.User>> getPendingUsers() async {
    debugPrint('📡 Fetching pending users...');
    final response =
        await _supabase.from('profiles').select().eq('status', 'pending');

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} pending users from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  Future<List<app_models.User>> getRejectedUsers() async {
    debugPrint('📡 Fetching rejected users...');
    final response =
        await _supabase.from('profiles').select().eq('status', 'rejected');

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} rejected users from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  Future<void> updateUserStatus(String userId, String status) async {
    try {
      debugPrint('🔄 Updating user status: $userId -> $status');
      final response = await _supabase
          .from('profiles')
          .update({'status': status})
          .eq('id', userId)
          .select();

      if ((response as List).isEmpty) {
        throw Exception('Update failed: No rows updated. Check RLS policies.');
      }

      debugPrint('✅ User status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user status: $e');
      rethrow;
    }
  }

  Future<void> inviteUser({
    required String email,
    required String role,
    required String department,
    required String name,
  }) async {
    // In a real app, this would trigger a Supabase Edge Function to send an invite email.
    // For now, we'll just create a profile placeholder if possible, or assume the user
    // will sign up and we'll auto-approve them if we had a pre-approved list.
    //
    // Since we can't easily create a user without them signing up in Supabase Auth,
    // we will just rely on the standard signup flow + admin approval.
    //
    // However, if we wanted to pre-approve, we could have a 'whitelisted_emails' table.
    //
    // For this implementation, "Invite" will just be a UI action that maybe sends an email intent
    // or we can just skip it for now and focus on the Approval flow which is the core request.
    //
    // Let's implement a simple "Pre-approve" mechanism by creating a profile stub?
    // No, that might conflict with the trigger that creates profiles on signup.
    //
    // Best approach for now: Just rely on the Approval Flow.
    // "Invite" can just be sending an email to the user telling them to sign up.

    // For now, we will just return. The UI can launch an email client.
  }

  Future<app_models.User?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();
      return app_models.User.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _supabase
        .from('profiles')
        .update({'fcm_token': token}).eq('id', userId);
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? department,
    String? bio,
    String? phone,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> updates = {};

    if (name != null) updates['name'] = name;
    if (department != null) updates['department'] = department;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null)
      updates['avatar_url'] = avatarUrl; // Fix potential bug if this was missed

    // Note: fcm_token is handled separately to avoid overwriting it during profile edits

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<String?> uploadProfilePicture(Uint8List bytes, String userId) async {
    try {
      debugPrint('📸 Starting profile picture upload for user: $userId');
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('📸 Uploading to bucket: profile-pictures, file: $fileName');
      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(fileName, bytes);

      final url =
          _supabase.storage.from('profile-pictures').getPublicUrl(fileName);

      debugPrint('✅ Profile picture uploaded successfully: $url');
      return url;
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading profile picture: $e');
      debugPrint('Stack trace: $stackTrace');

      // Check if it's a bucket not found error
      if (e.toString().contains('Bucket not found') ||
          e.toString().contains('bucket') ||
          e.toString().contains('404')) {
        debugPrint(
            '💡 Hint: Create "profile-pictures" bucket in Supabase Storage');
      }

      return null;
    }
  }

  // --- Attendance Records ---

  Future<void> saveRecord(AttendanceRecord record) async {
    await _supabase.from('attendance_records').insert({
      'user_id': record.userId,
      'type': record.type.toString(),
      'timestamp': record.timestamp,
      'location_lat': record.location?.lat,
      'location_lng': record.location?.lng,
      'device_id': record.deviceId,
      'biometric_verified': record.biometricVerified,
      'photo_url': record.photoUrl,
      'verification_method': record.verificationMethod,
    });
  }

  Future<List<AttendanceRecord>> getRecords() async {
    final response = await _supabase
        .from('attendance_records')
        .select()
        .order('timestamp', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) {
      // Map Supabase fields back to our model
      return AttendanceRecord(
        id: json['id'],
        userId: json['user_id'],
        type: _parseAttendanceType(json['type']),
        timestamp: json['timestamp'],
        location: json['location_lat'] != null
            ? Location(
                lat: json['location_lat'],
                lng: json['location_lng'],
              )
            : null,
      );
    }).toList();
  }

  Future<List<AttendanceRecord>> getUserRecords(String userId) async {
    final response = await _supabase
        .from('attendance_records')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) {
      return AttendanceRecord(
        id: json['id'],
        userId: json['user_id'],
        type: _parseAttendanceType(json['type']),
        timestamp: json['timestamp'],
        location: json['location_lat'] != null
            ? Location(
                lat: json['location_lat'],
                lng: json['location_lng'],
              )
            : null,
      );
    }).toList();
  }

  AttendanceType _parseAttendanceType(String typeStr) {
    // Handle "AttendanceType.CLOCK_IN" string from DB
    if (typeStr.contains('CLOCK_IN')) return AttendanceType.CLOCK_IN;
    if (typeStr.contains('CLOCK_OUT')) return AttendanceType.CLOCK_OUT;
    if (typeStr.contains('BREAK_START')) return AttendanceType.BREAK_START;
    if (typeStr.contains('BREAK_END')) return AttendanceType.BREAK_END;
    return AttendanceType.CLOCK_IN; // Default fallback
  }

  /// Get user records for a specific date range
  Future<List<AttendanceRecord>> getUserRecordsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startTimestamp = startDate.millisecondsSinceEpoch;
    final endTimestamp = endDate.millisecondsSinceEpoch;

    final response = await _supabase
        .from('attendance_records')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', startTimestamp)
        .lte('timestamp', endTimestamp)
        .order('timestamp', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) {
      return AttendanceRecord(
        id: json['id'],
        userId: json['user_id'],
        type: _parseAttendanceType(json['type']),
        timestamp: json['timestamp'],
        location: json['location_lat'] != null
            ? Location(
                lat: json['location_lat'],
                lng: json['location_lng'],
              )
            : null,
      );
    }).toList();
  }

  // --- Messages ---

  /// Send a message from sender to recipient
  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String message,
  }) async {
    await _supabase.from('messages').insert({
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message': message,
    });
  }

  /// Get conversation between two users (sorted by newest first)
  Future<List<Map<String, dynamic>>> getConversation(
    String userId1,
    String userId2,
  ) async {
    final response = await _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles!messages_sender_id_fkey(name),
          recipient:profiles!messages_recipient_id_fkey(name)
        ''')
        .or('and(sender_id.eq.$userId1,recipient_id.eq.$userId2),and(sender_id.eq.$userId2,recipient_id.eq.$userId1)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get all messages for a user (received messages)
  Future<List<Map<String, dynamic>>> getMessagesForUser(String userId) async {
    final response = await _supabase.from('messages').select('''
          *,
          sender:profiles!messages_sender_id_fkey(name, role),
          recipient:profiles!messages_recipient_id_fkey(name)
        ''').eq('recipient_id', userId).order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _supabase.from('messages').update({'read': true}).eq('id', messageId);
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from('messages')
        .select('id')
        .eq('recipient_id', userId)
        .eq('read', false)
        .count(CountOption.exact);

    return response.count ?? 0;
  }

  /// Subscribe to new messages for real-time updates
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String userId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // --- Notification Settings ---

  /// Get all notification settings
  Future<List<Map<String, dynamic>>> getNotificationSettings() async {
    final response = await _supabase
        .from('notification_settings')
        .select()
        .order('type', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Update a notification setting
  Future<void> updateNotificationSetting({
    required String id,
    bool? enabled,
    String? time,
    String? message,
    List<String>? daysOfWeek,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (enabled != null) updates['enabled'] = enabled;
    if (time != null) updates['time'] = time;
    if (message != null) updates['message'] = message;
    if (daysOfWeek != null) updates['days_of_week'] = daysOfWeek;

    await _supabase.from('notification_settings').update(updates).eq('id', id);
  }

  /// Create a new notification setting
  Future<void> createNotificationSetting({
    required String type,
    required bool enabled,
    required String time,
    required String message,
    required List<String> daysOfWeek,
  }) async {
    await _supabase.from('notification_settings').insert({
      'type': type,
      'enabled': enabled,
      'time': time,
      'message': message,
      'days_of_week': daysOfWeek,
    });
  }

  /// Delete a notification setting
  Future<void> deleteNotificationSetting(String id) async {
    await _supabase.from('notification_settings').delete().eq('id', id);
  }

  // --- Custom Notifications (Realtime) ---

  /// Send a custom notification to all employees
  Future<void> sendCustomNotification({
    required String title,
    required String message,
  }) async {
    await _supabase.from('custom_notifications').insert({
      'title': title,
      'message': message,
      'created_by': _supabase.auth.currentUser?.id,
    });
  }

  /// Subscribe to new custom notifications
  Stream<Map<String, dynamic>> subscribeToCustomNotifications() {
    final controller = StreamController<Map<String, dynamic>>();

    debugPrint('🔔 Subscribing to public:custom_notifications');
    _supabase
        .channel('public:custom_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'custom_notifications',
          callback: (payload) {
            debugPrint(
                '🔔 Notification Payload received: ${payload.newRecord}');
            if (payload.newRecord != null) {
              controller.add(payload.newRecord!);
            }
          },
        )
        .subscribe((status, [error]) {
      debugPrint('🔔 Subscription status: $status ${error ?? ""}');
    });

    return controller.stream;
  }

  Future<List<ReportData>> getAttendanceReport(
      DateTime start, DateTime end) async {
    final employees = await getAllEmployees();
    List<ReportData> reportData = [];

    for (var employee in employees) {
      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', employee.id)
          .gte('timestamp', start.millisecondsSinceEpoch)
          .lte('timestamp', end.millisecondsSinceEpoch)
          .order('timestamp');

      final List<dynamic> data = response as List<dynamic>;
      final records = data
          .map((json) => AttendanceRecord(
                id: json['id'],
                userId: json['user_id'],
                type: _parseAttendanceType(json['type']),
                timestamp: json['timestamp'],
                location: json['location_lat'] != null
                    ? Location(
                        lat: json['location_lat'],
                        lng: json['location_lng'],
                      )
                    : null,
              ))
          .toList();

      reportData.add(ReportData(user: employee, records: records));
    }

    return reportData;
  }

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
      print('Error getting device binding: $e');
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
      print('Error registering device: $e');
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
      rethrow; // Rethrow so the UI can show the error
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

  // --- Photo Upload ---

  Future<String?> uploadAttendancePhoto(
      Uint8List bytes, String fileName) async {
    try {
      await _supabase.storage
          .from('attendance-photos')
          .uploadBinary(fileName, bytes);

      final url =
          _supabase.storage.from('attendance-photos').getPublicUrl(fileName);

      return url;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  // --- Tasks ---

  /// Create a new task for a user
  Future<void> createTask(Task task) async {
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    await _supabase.from('tasks').insert({
      'user_id': task.userId,
      'task_date': DateTime.utc(task.date.year, task.date.month, task.date.day)
          .toIso8601String(),
      'title': task.title,
      'description': task.description,
      'is_completed': task.isCompleted,
      'start_time': formatTime(task.startTime),
      'end_time': formatTime(task.endTime),
      'actual_end_time': formatTime(task.actualEndTime),
    });
  }

  /// Get tasks for a user on a specific date
  Future<List<Task>> getUserTasksForDate(String userId, DateTime date) async {
    final start = DateTime.utc(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .gte('task_date', start.toIso8601String())
        .lt('task_date', end.toIso8601String())
        .order('created_at', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Update the completion status of a task
  Future<void> updateTaskStatus(String taskId, bool isCompleted,
      {TimeOfDay? actualEndTime}) async {
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    await _supabase.from('tasks').update({
      'is_completed': isCompleted,
      'actual_end_time': isCompleted ? formatTime(actualEndTime) : null,
    }).eq('id', taskId);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  /// Get tasks for all employees within a date range (for admin reports)
  Future<List<Task>> getTasksForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .gte('task_date',
            DateTime.utc(start.year, start.month, start.day).toIso8601String())
        .lte(
            'task_date',
            DateTime.utc(end.year, end.month, end.day, 23, 59, 59)
                .toIso8601String())
        .order('task_date', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
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

  /// Auto sign-out users who are still clocked in after office hours
  /// This should be called by a scheduled task/cron job
  /// Auto sign-out user and return logs
  Future<List<String>> autoSignOutUser(String userId) async {
    List<String> logs = [];
    logs.add('👤 Checking user: $userId');
    try {
      // Get today's records for the user
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final records = await getUserRecordsForDateRange(
        userId,
        todayStart,
        todayEnd,
      );
      logs.add('   - Found ${records.length} records today');

      // Check if there's an unmatched clock-in
      final clockIns =
          records.where((r) => r.type == AttendanceType.CLOCK_IN).toList();
      final clockOuts =
          records.where((r) => r.type == AttendanceType.CLOCK_OUT).toList();

      if (clockIns.isNotEmpty && clockOuts.length < clockIns.length) {
        logs.add('   - ⚠️ Unmatched Clock-In found. Attempting sign-out...');
        // Create auto sign-out record
        await _supabase.from('attendance_records').insert({
          'user_id': userId,
          'type': 'AttendanceType.CLOCK_OUT',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'biometric_verified': false,
          'verification_method':
              'none', // 'manual' failed, 'none' is explicitly allowed per model comments
        });

        debugPrint('✅ Auto signed out user: $userId');
        logs.add('   - ✅ SUCCESS: Auto signed out user');
      } else {
        logs.add('   - OK: No unmatched clock-ins');
      }
    } catch (e) {
      debugPrint('❌ Error auto signing out user: $e');
      logs.add('   - ❌ ERROR: $e');
    }
    return logs;
  }

  Future<List<app_models.User>> getAllActiveUsers() async {
    debugPrint('📡 Fetching all active users...');
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('status', 'active'); // Fetch all active users (Employees + Admins)

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} active users from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  /// Get a list of users who are currently signed in (have an unmatched CLOCK_IN)
  Future<Map<String, dynamic>> getUsersCurrentlySignedInWithLogs() async {
    List<String> logs = [];
    logs.add('🔍 Checking for currently signed-in users...');
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // 1. Fetch all active users
      final employees = await getAllActiveUsers();
      if (employees.isEmpty) {
        logs.add('   - No active users found.');
        return {'users': [], 'logs': logs};
      }

      // 2. Fetch all records for today
      final response = await _supabase
          .from('attendance_records')
          .select()
          .gte('timestamp', todayStart.millisecondsSinceEpoch)
          .lte('timestamp', now.millisecondsSinceEpoch)
          .order('timestamp', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final allRecords = data.map((json) {
        return AttendanceRecord(
          id: json['id'],
          userId: json['user_id'],
          type: _parseAttendanceType(json['type']),
          timestamp: json['timestamp'],
          location: null,
        );
      }).toList();

      List<String> signedInUsers = [];

      for (var employee in employees) {
        final employeeRecords =
            allRecords.where((r) => r.userId == employee.id).toList();

        if (employeeRecords.isEmpty) continue;

        // Determine current status
        final clockIns = employeeRecords
            .where((r) => r.type == AttendanceType.CLOCK_IN)
            .toList();
        final clockOuts = employeeRecords
            .where((r) => r.type == AttendanceType.CLOCK_OUT)
            .toList();

        if (clockIns.isNotEmpty && clockOuts.length < clockIns.length) {
          signedInUsers.add(employee.id);
        }
      }
      logs.add('📊 Found ${signedInUsers.length} users to sign out');
      return {'users': signedInUsers, 'logs': logs};
    } catch (e) {
      debugPrint('❌ Error getting signed in users: $e');
      logs.add('❌ CRITICAL ERROR scanning users: $e');
      return {'users': [], 'logs': logs};
    }
  }

  /// Automatically end breaks that are longer than 1 hour
  Future<List<String>> autoEndStaleBreaks() async {
    List<String> logs = [];
    logs.add('☕ Checking for stale breaks (> 1 hour)...');

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final oneHourMillis = const Duration(hours: 1).inMilliseconds;

      // 1. Fetch all active users
      final employees = await getAllActiveUsers();
      if (employees.isEmpty) {
        return logs..add('   - No active users found.');
      }

      // 2. Fetch all records for today
      final response = await _supabase
          .from('attendance_records')
          .select()
          .gte('timestamp', todayStart.millisecondsSinceEpoch)
          .lte('timestamp', now.millisecondsSinceEpoch)
          .order('timestamp', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final allRecords = data.map((json) {
        return AttendanceRecord(
          id: json['id'],
          userId: json['user_id'],
          type: _parseAttendanceType(json['type']),
          timestamp: json['timestamp'],
          location: null,
        );
      }).toList();

      int fixedCount = 0;

      for (var employee in employees) {
        final employeeRecords =
            allRecords.where((r) => r.userId == employee.id).toList();

        if (employeeRecords.isEmpty) continue;

        // Determine current status
        final lastRecord = employeeRecords.last;

        if (lastRecord.type == AttendanceType.BREAK_START) {
          final breakDuration =
              now.millisecondsSinceEpoch - lastRecord.timestamp;

          if (breakDuration > oneHourMillis) {
            logs.add(
                '   - ⚠️ ${employee.name} has been on break for ${(breakDuration / 60000).toStringAsFixed(0)} mins. Auto ending...');

            // Insert BREAK_END record
            await _supabase.from('attendance_records').insert({
              'user_id': employee.id,
              'type': 'AttendanceType.BREAK_END',
              // Set timestamp to exactly 1 hour after start? Or now?
              // User request: "break should automatically ends after 1 hour"
              // Best UX: End it "Now" so they see the real time, OR end it at 1h mark?
              // Implementation: End it NOW, so the system reflects "We caught you now".
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'biometric_verified': false,
              'verification_method': 'none',
            });
            fixedCount++;
          }
        }
      }

      logs.add(fixedCount > 0
          ? '✅ Auto-ended $fixedCount stale breaks.'
          : '   - No stale breaks found.');
    } catch (e) {
      debugPrint('❌ Error checking stale breaks: $e');
      logs.add('❌ CRITICAL ERROR checking breaks: $e');
    }
    return logs;
  }

  // Keeping legacy method for compatibility if needed, but redirecting
  Future<List<String>> getUsersCurrentlySignedIn() async {
    final result = await getUsersCurrentlySignedInWithLogs();
    return result['users'] as List<String>;
  }

  // --- Notice Board Methods ---

  /// Fetch all notices ordered by creation date (newest first)
  Future<List<Notice>> getNotices() async {
    try {
      final response = await _supabase
          .from('notices')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Notice.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching notices: $e');
      return [];
    }
  }

  /// Create a new notice
  Future<void> createNotice(Notice notice) async {
    await _supabase.from('notices').insert({
      'title': notice.title,
      'content': notice.content,
      'priority': notice.priority,
      'category': notice.category,
      'created_by': _supabase.auth.currentUser!.id,
    });
  }

  /// Update an existing notice
  Future<void> updateNotice(Notice notice) async {
    await _supabase.from('notices').update({
      'title': notice.title,
      'content': notice.content,
      'priority': notice.priority,
      'category': notice.category,
    }).eq('id', notice.id);
  }

  /// Delete a notice
  Future<void> deleteNotice(String id) async {
    await _supabase.from('notices').delete().eq('id', id);
  }

  // --- Stories (Announcements) ---

  // --- Leave Management ---

  /// Submit a new leave request
  Future<void> submitLeaveRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    required String reason,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('leave_requests').insert({
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'leave_type': leaveType,
      'reason': reason,
      'status': 'Pending',
    });
  }

  /// Get leave requests for the current user
  Future<List<LeaveRequest>> getMyLeaveRequests() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('leave_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => LeaveRequest.fromJson(json)).toList();
  }

  /// Get all leave requests (Admin only)
  Future<List<LeaveRequest>> getAllLeaveRequests() async {
    // We join with profiles to get user names
    // Fetch from the view that already joins profiles
    final response = await _supabase
        .from('admin_leave_requests_view')
        .select()
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => LeaveRequest.fromJson(json)).toList();
  }

  /// Update leave request status (Admin only)
  Future<void> updateLeaveStatus({
    required String requestId,
    required String status,
    String? adminComment,
  }) async {
    try {
      await _supabase.from('leave_requests').update({
        'status': status,
        'admin_comment': adminComment,
      }).eq('id', requestId);
    } catch (e) {
      debugPrint('❌ Error updating leave status: $e');
      rethrow;
    }
  }

  /// Stream leave requests for the current user (Real-time)
  Stream<List<LeaveRequest>> streamMyLeaveRequests() {
    return _supabase
        .from('leave_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .map(
            (data) => data.map((json) => LeaveRequest.fromJson(json)).toList());
  }

  /// Stream all leave requests for Admin (Real-time)
  /// Note: .stream() does not support complex joins like .select('*, profiles(*)').
  /// We will stream the requests and fetch profiles separately or rely on caching/join-in-memory if needed.
  /// However, for the list view, we need user names.
  /// Strategy: Stream the IDs/Status, and use a FutureBuilder for details OR restart stream on changes?
  /// Better Strategy: Use the `admin_leave_requests_view`!
  /// But Realtime on View requires extra setup.
  /// Simpler: Stream `leave_requests` and for each item in the list, we show the data.
  /// BUT we need the name.
  /// Let's use the .stream() but fetch profiles in the UI or fetch all profiles once.
  /// Actually, best UX: Stream logic in the Service returns a Stream of enriched objects? No, too complex.
  /// Let's stick to: Stream the raw requests, and in the UI, use a `FutureBuilder` to get the name if missing?
  /// OR, since the user already has `getAllLeaveRequests` which does a join, we can just poll it?
  /// User wanted IMMEDIATE updates.
  /// Let's try to stream `leave_requests` and whenever it emits, we call `getAllLeaveRequests()` to fetch full data.
  Stream<List<LeaveRequest>> streamAllLeaveRequests() {
    return _supabase
        .from('leave_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((_) async => await getAllLeaveRequests());
  }

  // --- App Updates ---

  Future<AppVersion?> checkForUpdates() async {
    try {
      debugPrint('🔄 Checking for app updates...');

      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersionCode = int.parse(packageInfo.buildNumber);
      debugPrint('📱 Current Version Code: $currentVersionCode');

      // Get latest version from DB
      final response = await _supabase
          .from('app_versions')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('✅ No update information found in DB.');
        return null;
      }

      final latestVersion = AppVersion.fromJson(response);
      debugPrint('🚀 Latest Version Code: ${latestVersion.versionCode}');

      if (latestVersion.versionCode > currentVersionCode) {
        debugPrint('🌟 Update Available!');
        return latestVersion;
      } else {
        debugPrint('✅ App is up to date.');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }

  Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch user url');
    }
  }

  Future<void> publishAppVersion({
    required int versionCode,
    required String versionName,
    required String apkUrl,
    required String releaseNotes,
    required bool forceUpdate,
  }) async {
    try {
      await _supabase.from('app_versions').insert({
        'version_code': versionCode,
        'version_name': versionName,
        'apk_url': apkUrl,
        'release_notes': releaseNotes,
        'force_update': forceUpdate,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ App version published successfully!');
    } catch (e) {
      debugPrint('❌ Error publishing app version: $e');
      rethrow;
    }
  }
}
