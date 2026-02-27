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
import 'package:braand_app/models/leave_balance.dart';
import 'package:braand_app/models/leave_request.dart';
import 'package:braand_app/models/attendance_stats.dart';
import '../models/app_version.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'offline_sync_service.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

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
    final Map<String, dynamic> data = {
      'user_id': record.userId,
      'type': record.type.toString(),
      'timestamp': record.timestamp,
      'location_lat': record.location?.lat,
      'location_lng': record.location?.lng,
      'device_id': record.deviceId,
      'biometric_verified': record.biometricVerified,
      'photo_url': record.photoUrl,
      'verification_method': record.verificationMethod,
      'mood': record.mood,
    };

    try {
      await _supabase.from('attendance_records').insert(data);
      debugPrint('✅ Attendance record saved successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to save record to Supabase, queuing offline: $e');
      // If network error, queue it
      final OfflineSyncService offlineService = OfflineSyncService();
      await offlineService.queueAction(
        action: 'attendance_record',
        data: data,
      );
    }
  }

  /// FOR OFFLINE SYNC ONLY: Directly insert pre-formatted data
  Future<void> manualInsertAttendance(Map<String, dynamic> data) async {
    await _supabase.from('attendance_records').insert(data);
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
        mood: json['mood'],
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
        mood: json['mood'],
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
        mood: json['mood'],
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
      'admin_assessment': task.adminAssessment,
      'priority': task.priority,
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

  /// Update the Admin Assessment of a task
  Future<void> updateTaskAssessment(String taskId, String assessment) async {
    await _supabase.from('tasks').update({
      'admin_assessment': assessment,
    }).eq('id', taskId);
  }

  /// Update the Priority of a task
  Future<void> updateTaskPriority(String taskId, String priority) async {
    await _supabase.from('tasks').update({
      'priority': priority,
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

  /// ADMIN ONLY: Scan ALL active users and auto sign-out anyone still clocked in
  Future<List<String>> autoSignOutAllUsers() async {
    List<String> logs = [];
    logs.add('👮 ADMIN ACTION: Starting Global Auto Sign-Out Scan...');

    try {
      // 1. Fetch ALL active users
      final allUsers = await getAllActiveUsers();
      if (allUsers.isEmpty) {
        logs.add('   - No active users found in database.');
        return logs;
      }
      logs.add('   - Found ${allUsers.length} active users to scan.');

      // 2. Iterate and check each user
      int signedOutCount = 0;
      for (final user in allUsers) {
        // Skip calling the robust "autoSignOutUser" to update logs per user
        final userLogs = await autoSignOutUser(user.id);

        // If the logs indicate a success, increment count
        if (userLogs.any((l) => l.contains('SUCCESS'))) {
          signedOutCount++;
          logs.add('   - ✅ Clocked out: ${user.name}');
        }
      }

      logs.add(
          '🏁 Global Scan Complete. Auto-signed out $signedOutCount users.');
    } catch (e) {
      debugPrint('❌ Error in global auto sign-out: $e');
      logs.add('❌ CRITICAL ERROR in global scan: $e');
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

    // Update pending leaves
    try {
      final days = endDate.difference(startDate).inDays + 1;
      final year = startDate.year;

      // Fetch balance first
      final balance = await getLeaveBalance(userId, year);
      await _supabase.from('leave_balances').update({
        'pending_leaves': balance.pendingLeaves + days,
      }).eq('id', balance.id);
    } catch (e) {
      debugPrint('⚠️ Error updating pending leaves: $e');
    }
  }

  /// Get leave balance for a user and year
  Future<LeaveBalance> getLeaveBalance(String userId, int year) async {
    try {
      final response = await _supabase
          .from('leave_balances')
          .select()
          .eq('user_id', userId)
          .eq('year', year)
          .maybeSingle();

      if (response == null) {
        // Initialize default
        final newBalance = await _supabase
            .from('leave_balances')
            .insert({
              'user_id': userId,
              'year': year,
              'total_leaves': 12,
              'used_leaves': 0,
              'pending_leaves': 0,
            })
            .select()
            .single();
        return LeaveBalance.fromJson(newBalance);
      }
      return LeaveBalance.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting leave balance: $e');
      // Return dummy if error to avoid crash
      return LeaveBalance(id: '', userId: userId, year: year);
    }
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
      // Fetch request first to get details
      final requestData = await _supabase
          .from('leave_requests')
          .select()
          .eq('id', requestId)
          .single();
      final LeaveRequest request = LeaveRequest.fromJson(requestData);

      await _supabase.from('leave_requests').update({
        'status': status,
        'admin_comment': adminComment,
      }).eq('id', requestId);

      // Update Leave Balance
      if (status == 'Approved' && request.status != 'Approved') {
        // Pending -> Approved
        final days = request.endDate.difference(request.startDate).inDays + 1;
        final year = request.startDate.year;
        final balance = await getLeaveBalance(request.userId, year);

        await _supabase.from('leave_balances').update({
          'used_leaves': balance.usedLeaves + days,
          'pending_leaves': (balance.pendingLeaves - days) < 0
              ? 0
              : (balance.pendingLeaves - days),
        }).eq('id', balance.id);
      } else if (status == 'Rejected' && request.status == 'Pending') {
        // Pending -> Rejected
        final days = request.endDate.difference(request.startDate).inDays + 1;
        final year = request.startDate.year;
        final balance = await getLeaveBalance(request.userId, year);

        await _supabase.from('leave_balances').update({
          'pending_leaves': (balance.pendingLeaves - days) < 0
              ? 0
              : (balance.pendingLeaves - days),
        }).eq('id', balance.id);
      }
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

  // --- Monthly Tasks ---

  /// Create a new monthly task (Admin only)
  Future<void> createMonthlyTask({
    required String title,
    String? description,
    required int month,
    required int year,
    String? assignedTo,
    bool isPrivate = false,
    String priority = 'Medium',
  }) async {
    try {
      await _supabase.from('monthly_tasks').insert({
        'title': title,
        'description': description,
        'task_type': 'monthly',
        'month': month,
        'year': year,
        'assigned_to': assignedTo,
        'is_private': isPrivate,
        'created_by': _supabase.auth.currentUser?.id,
        'priority': priority,
      });
      debugPrint('✅ Monthly task created successfully');

      // Send Notification
      if (assignedTo != null) {
        await sendNotification(
          userId: assignedTo,
          title: 'New Monthly Task',
          body: 'You have been assigned: $title',
          data: {'type': 'task', 'taskId': 'monthly'},
        );
      } else {
        // Notify all employees
        final employees = await getEmployees();
        for (var emp in employees) {
          await sendNotification(
            userId: emp['id'],
            title: 'New Monthly Task',
            body: '$title (All Employees)',
            data: {'type': 'task', 'taskId': 'monthly'},
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating monthly task: $e');
      rethrow;
    }
  }

  /// Create a new date-specific task (Admin only)
  Future<void> createDailyTask({
    required String title,
    String? description,
    required DateTime specificDate,
    int? timeLimitValue,
    String? timeUnit,
    String? assignedTo,
    bool isPrivate = false,
    String priority = 'Medium',
  }) async {
    try {
      // Convert time limit to minutes
      int? timeLimitMinutes;
      DateTime? deadlineTime;

      if (timeLimitValue != null && timeUnit != null) {
        switch (timeUnit) {
          case 'minutes':
            timeLimitMinutes = timeLimitValue;
            break;
          case 'hours':
            timeLimitMinutes = timeLimitValue * 60;
            break;
          case 'days':
            timeLimitMinutes = timeLimitValue * 60 * 24;
            break;
        }
        deadlineTime = specificDate.add(Duration(minutes: timeLimitMinutes!));
      }

      await _supabase.from('monthly_tasks').insert({
        'title': title,
        'description': description,
        'task_type': 'daily',
        'specific_date': specificDate.toIso8601String().split('T')[0],
        'time_limit_minutes': timeLimitMinutes,
        'time_unit': timeUnit,
        'deadline_time': deadlineTime?.toIso8601String(),
        'assigned_to': assignedTo,
        'is_private': isPrivate,
        'priority': priority,
        'created_by': _supabase.auth.currentUser?.id,
      });
      debugPrint('✅ Daily task created successfully');

      // Send Notification
      if (assignedTo != null) {
        await sendNotification(
          userId: assignedTo,
          title: 'New Daily Task',
          body: 'You have been assigned: $title',
          data: {'type': 'task', 'taskId': 'daily'},
        );
      } else {
        // Notify all employees
        final employees = await getEmployees();
        for (var emp in employees) {
          await sendNotification(
            userId: emp['id'],
            title: 'New Daily Task',
            body: '$title (All Employees)',
            data: {'type': 'task', 'taskId': 'daily'},
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating daily task: $e');
      rethrow;
    }
  }

  /// Get all employees for assignment selector
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final profiles = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'Employee')
          .order('name');
      return List<Map<String, dynamic>>.from(profiles as List);
    } catch (e) {
      debugPrint('❌ Error loading employees: $e');
      rethrow;
    }
  }

  /// Get all monthly tasks for a specific month/year
  Future<List<Map<String, dynamic>>> getMonthlyTasks({
    required int month,
    required int year,
    String? userId,
  }) async {
    try {
      if (userId != null) {
        // For employees: Join with user_monthly_tasks to get completion status
        final response = await _supabase
            .from('monthly_tasks')
            .select('''
              *,
              user_monthly_tasks!left(is_completed, completed_at, started_at)
            ''')
            .eq('task_type', 'monthly')
            .eq('month', month)
            .eq('year', year)
            .eq('user_monthly_tasks.user_id', userId)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      } else {
        // For admins: Just get all tasks
        final response = await _supabase
            .from('monthly_tasks')
            .select()
            .eq('task_type', 'monthly')
            .eq('month', month)
            .eq('year', year)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      }
    } catch (e) {
      debugPrint('❌ Error fetching monthly tasks: $e');
      return [];
    }
  }

  /// Get all date-specific tasks for a specific date
  Future<List<Map<String, dynamic>>> getDailyTasks({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      if (userId != null) {
        // For employees: Join with user_monthly_tasks to get completion status
        final response = await _supabase
            .from('monthly_tasks')
            .select('''
              *,
              user_monthly_tasks!left(is_completed, completed_at, started_at)
            ''')
            .eq('task_type', 'daily')
            .eq('specific_date', dateStr)
            .eq('user_monthly_tasks.user_id', userId)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      } else {
        // For admins: Just get all tasks
        final response = await _supabase
            .from('monthly_tasks')
            .select()
            .eq('task_type', 'daily')
            .eq('specific_date', dateStr)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(response as List);
      }
    } catch (e) {
      debugPrint('❌ Error fetching daily tasks: $e');
      return [];
    }
  }

  /// Get comprehensive performance metrics for an employee for a specific month
  Future<Map<String, dynamic>> getEmployeePerformanceMetrics({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      // 1. Fetch Tasks (Monthly + Daily)
      // We need tasks that are NOT private, and are either assigned to this user OR assigned to all (null)
      final tasksResponse = await _supabase
          .from('monthly_tasks')
          .select(
              '*, user_monthly_tasks!left(is_completed, completed_at, user_id)')
          .or('assigned_to.eq.$userId,assigned_to.is.null')
          .eq('is_private', false)
          .or('and(task_type.eq.monthly,month.eq.$month,year.eq.$year),and(task_type.eq.daily,specific_date.gte.${startDate.toIso8601String().split('T')[0]},specific_date.lte.${endDate.toIso8601String().split('T')[0]})');

      int totalTasks = 0;
      int completedTasks = 0;
      final List<Map<String, dynamic>> tasksList =
          List<Map<String, dynamic>>.from(tasksResponse as List);

      for (var task in tasksList) {
        totalTasks++;
        // Check if completed by user
        final userStatusList = task['user_monthly_tasks'];
        if (userStatusList != null && userStatusList is List) {
          for (var status in userStatusList) {
            if (status['user_id'] == userId && status['is_completed'] == true) {
              completedTasks++;
              break;
            }
          }
        }
      }

      // 2. Fetch Attendance
      // Get all records for this user in this month
      // Note: timestamp is int (milliseconds since epoch)
      final startTs = startDate.millisecondsSinceEpoch;
      final endTs = endDate.add(const Duration(days: 1)).millisecondsSinceEpoch;

      final attendanceResponse = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId) // Fixed column name from userId to user_id
          .gte('timestamp', startTs)
          .lte('timestamp', endTs)
          .order('timestamp');

      final List<dynamic> records = attendanceResponse as List;
      final Set<String> presentDays = {};
      int lateArrivals = 0;

      // Fetch office hours to calc punctuality
      final settingsResponse =
          await _supabase.from('office_hours_settings').select().maybeSingle();
      final startHour =
          settingsResponse != null ? settingsResponse['start_hour'] : 9;
      final startMinute =
          settingsResponse != null ? settingsResponse['start_minute'] : 30;

      for (var record in records) {
        if (record['type'] == 'CLOCK_IN') {
          final time = DateTime.fromMillisecondsSinceEpoch(record['timestamp']);
          final dateKey = '${time.year}-${time.month}-${time.day}';
          presentDays.add(dateKey);

          // Check for late arrival
          // Create threshold time for that specific day
          final threshold = DateTime(
            time.year,
            time.month,
            time.day,
            startHour,
            startMinute +
                15, // 15 min grace period? Let's stick to strict or small buffer
          );

          if (time.isAfter(threshold)) {
            lateArrivals++;
          }
        }
      }

      // 3. Fetch Leaves
      final leavesResponse = await _supabase
          .from('leave_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'Approved')
          .or('start_date.lte.${endDate.toIso8601String()},end_date.gte.${startDate.toIso8601String()}');
      // Overlap logic: Start <= EndOfRange AND End >= StartOfRange

      int leaveDays = 0;
      for (var leave in leavesResponse) {
        final start = DateTime.parse(leave['start_date']);
        final end = DateTime.parse(leave['end_date']);

        // Clamp dates to the selected month
        final effectiveStart = start.isBefore(startDate) ? startDate : start;
        final effectiveEnd = end.isAfter(endDate) ? endDate : end;

        if (effectiveEnd.isAfter(effectiveStart) ||
            effectiveEnd.isAtSameMomentAs(effectiveStart)) {
          leaveDays += effectiveEnd.difference(effectiveStart).inDays + 1;
        }
      }

      return {
        'tasks': {
          'total': totalTasks,
          'completed': completedTasks,
          'rate': totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0,
        },
        'attendance': {
          'present': presentDays.length,
          'late': lateArrivals,
          'punctuality': presentDays.isNotEmpty
              ? ((presentDays.length - lateArrivals) / presentDays.length) * 100
              : 0.0,
        },
        'leaves': {
          'total': leaveDays,
        },
      };
    } catch (e) {
      debugPrint('❌ Error fetching performance metrics: $e');
      return {
        'tasks': {'total': 0, 'completed': 0, 'rate': 0.0},
        'attendance': {'present': 0, 'late': 0, 'punctuality': 0.0},
        'leaves': {'total': 0},
      };
    }
  }

  /// Update monthly task status and sync is_completed
  Future<void> updateMonthlyTaskStatus({
    required String taskId,
    required String userId,
    required String status,
  }) async {
    try {
      final isCompleted = status == 'Completed';
      final now = DateTime.now().toIso8601String();

      // Check if record exists
      final existing = await _supabase
          .from('user_monthly_tasks')
          .select()
          .eq('user_id', userId)
          .eq('task_id', taskId)
          .maybeSingle();

      if (existing == null) {
        // Insert new record
        await _supabase.from('user_monthly_tasks').insert({
          'user_id': userId,
          'task_id': taskId,
          'status': status,
          'is_completed': isCompleted,
          'completed_at': isCompleted ? now : null,
          'started_at': now,
        });
      } else {
        // Update existing
        await _supabase
            .from('user_monthly_tasks')
            .update({
              'status': status,
              'is_completed': isCompleted,
              'completed_at': isCompleted ? now : null,
            })
            .eq('user_id', userId)
            .eq('task_id', taskId);
      }
    } catch (e) {
      debugPrint('❌ Error updating task status: $e');
      rethrow;
    }
  }

  /// Toggle monthly task completion for a user
  // Deprecated: Use updateMonthlyTaskStatus instead
  Future<void> toggleMonthlyTaskCompletion({
    required String taskId,
    required String userId,
    required bool isCompleted,
  }) async {
    return updateMonthlyTaskStatus(
      taskId: taskId,
      userId: userId,
      status: isCompleted ? 'Completed' : 'Pending',
    );
  }

  /// Mark task as started (for progress tracking)
  Future<void> startTask({
    required String taskId,
    required String userId,
  }) async {
    try {
      final existing = await _supabase
          .from('user_monthly_tasks')
          .select()
          .eq('user_id', userId)
          .eq('task_id', taskId)
          .maybeSingle();

      if (existing == null) {
        // Insert new record with started_at
        await _supabase.from('user_monthly_tasks').insert({
          'user_id': userId,
          'task_id': taskId,
          'is_completed': false,
          'started_at': DateTime.now().toIso8601String(),
        });
      } else if (existing['started_at'] == null) {
        // Update existing record to set started_at
        await _supabase
            .from('user_monthly_tasks')
            .update({
              'started_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('task_id', taskId);
      }
      debugPrint('✅ Task started');
    } catch (e) {
      debugPrint('❌ Error starting task: $e');
      rethrow;
    }
  }

  /// Delete a monthly task (Admin only)
  Future<void> deleteMonthlyTask(String taskId) async {
    try {
      await _supabase.from('monthly_tasks').delete().eq('id', taskId);
      debugPrint('✅ Monthly task deleted');
    } catch (e) {
      debugPrint('❌ Error deleting monthly task: $e');
      rethrow;
    }
  }

  // --- Notifications ---

  /// Send a notification (Insert into DB)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Notification sent to $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  // --- Attendance Analytics ---
  Future<AttendanceStats> getAttendanceStats(
      String userId, int year, int month) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final endOfMonth = DateTime(year, month, daysInMonth, 23, 59, 59);

      // Fetch records for the month
      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', startOfMonth.millisecondsSinceEpoch)
          .lte('timestamp', endOfMonth.millisecondsSinceEpoch)
          .order('timestamp', ascending: true);

      final records = (response as List)
          .map((json) => AttendanceRecord(
                id: json['id'],
                userId: json['user_id'],
                type: _parseAttendanceType(json['type']),
                timestamp: json['timestamp'],
                location: null,
              ))
          .toList();

      if (records.isEmpty) {
        return AttendanceStats.empty();
      }

      // Fetch Office Hours
      TimeOfDay officeStart = const TimeOfDay(hour: 9, minute: 30); // Default
      try {
        final settings = await _supabase
            .from('office_hours_settings')
            .select()
            .maybeSingle();
        if (settings != null) {
          officeStart = TimeOfDay(
              hour: settings['start_hour'], minute: settings['start_minute']);
        }
      } catch (e) {
        // Fallback
      }

      int presentDays = 0;
      int lateDays = 0;
      double totalHours = 0;
      final Set<int> uniqueDays = {};

      // Group by day
      final Map<int, List<AttendanceRecord>> dailyRecords = {};
      for (var record in records) {
        final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
        final day = date.day;
        if (!dailyRecords.containsKey(day)) {
          dailyRecords[day] = [];
        }
        dailyRecords[day]!.add(record);
      }

      for (var entry in dailyRecords.entries) {
        final day = entry.key;
        final dailyList = entry.value;

        // Check Present
        // Look for CLOCK_IN

        // Find Clock-In
        AttendanceRecord? firstCheckIn;
        try {
          firstCheckIn =
              dailyList.firstWhere((r) => r.type == AttendanceType.CLOCK_IN);
        } catch (e) {
          // No clock in
        }

        if (firstCheckIn != null) {
          presentDays++;
          uniqueDays.add(day);

          // Check Late
          final checkInTime =
              DateTime.fromMillisecondsSinceEpoch(firstCheckIn.timestamp);
          final officeStartTime = DateTime(checkInTime.year, checkInTime.month,
              checkInTime.day, officeStart.hour, officeStart.minute);

          if (checkInTime
              .isAfter(officeStartTime.add(const Duration(minutes: 15)))) {
            lateDays++;
          }

          // Calculate Hours: Last Record Time - First IN Time
          final lastRecord = dailyList.last;
          if (lastRecord.timestamp > firstCheckIn.timestamp) {
            final durationMillis =
                lastRecord.timestamp - firstCheckIn.timestamp;
            totalHours += (durationMillis / (1000 * 60 * 60));
          }
        }
      }

      double avgHours = presentDays > 0 ? totalHours / presentDays : 0;

      return AttendanceStats(
        presentDays: presentDays,
        lateDays: lateDays,
        absentDays: 0, // Placeholder
        averageHours: avgHours,
        totalWorkingDays: 0,
      );
    } catch (e) {
      debugPrint('Error getting attendance stats: $e');
      return AttendanceStats.empty();
    }
  }
  // --- Banner Announcements ---

  Future<List<Map<String, dynamic>>> getBannerAnnouncements() async {
    try {
      final response = await _supabase
          .from('banner_announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // Filter expired announcements locally or in query if possible
      // (Query filter done in RLS/Policy usually, but explicit check here is good too)
      final data = response as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching banner announcements: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamBannerAnnouncements() {
    return _supabase
        .from('banner_announcements')
        .stream(primaryKey: ['id']).map((data) {
      // Filter and sort client-side to be safe against Realtime config issues
      final List<Map<String, dynamic>> list =
          List<Map<String, dynamic>>.from(data);
      list.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
      return list.where((e) => e['is_active'] == true).toList();
    });
  }

  Future<void> createBannerAnnouncement({
    required String message,
    DateTime? expiresAt,
  }) async {
    await _supabase.from('banner_announcements').insert({
      'message': message,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'created_by': _supabase.auth.currentUser?.id,
    });
  }

  Future<void> deleteBannerAnnouncement(String id) async {
    // Soft delete by setting is_active to false
    await _supabase
        .from('banner_announcements')
        .update({'is_active': false}).eq('id', id);
  }

  // --- Premium Features Logic ---

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

      int streak = 0;
      DateTime today = DateTime.now();
      DateTime checkDate = DateTime(today.year, today.month, today.day);

      // If the latest record is not today or yesterday, streak is broken
      if (uniqueDates.first
          .isBefore(checkDate.subtract(const Duration(days: 1)))) {
        return 0;
      }

      for (int i = 0; i < uniqueDates.length; i++) {
        if (uniqueDates[i] == checkDate ||
            uniqueDates[i] == checkDate.subtract(Duration(days: streak))) {
          if (uniqueDates[i] == checkDate ||
              uniqueDates[i] == checkDate.subtract(Duration(days: streak))) {
            streak++;
          } else {
            break;
          }
        } else {
          // If there's a gap, break
          if (uniqueDates[i]
              .isBefore(checkDate.subtract(Duration(days: streak)))) {
            break;
          }
        }
      }

      // Re-implementing simpler streak logic
      streak = 0;
      DateTime current = uniqueDates.first;

      // If the most recent is older than yesterday, streak is 0
      if (current.isBefore(checkDate.subtract(const Duration(days: 1)))) {
        return 0;
      }

      streak = 1;
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

  /// Get aggregated mood data for the last 7 days (Admin Insight)
  Future<Map<String, int>> getAggregatedMoods() async {
    try {
      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;

      final response = await _supabase
          .from('attendance_records')
          .select('mood')
          .not('mood', 'is', null)
          .gte('timestamp', sevenDaysAgo);

      final List<dynamic> data = response as List<dynamic>;
      final Map<String, int> moodCounts = {
        'rocket': 0,
        'smile': 0,
        'coffee': 0,
        'sleep': 0,
      };

      for (var item in data) {
        final mood = item['mood'] as String?;
        if (mood != null && moodCounts.containsKey(mood)) {
          moodCounts[mood] = moodCounts[mood]! + 1;
        }
      }

      return moodCounts;
    } catch (e) {
      debugPrint('❌ Error fetching aggregated moods: $e');
      return {};
    }
  }

  // --- Automated Daily Stand-up ---

  Future<Map<String, dynamic>> generateDailySummary() async {
    try {
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final recordsResponse = await _supabase
          .from('attendance_records')
          .select()
          .gte('timestamp', startOfDay);

      final List<dynamic> records = recordsResponse as List<dynamic>;

      int activeUsers =
          records.map((r) => r['user_id']).toSet().toList().length;
      int clockIns =
          records.where((r) => r['type'] == 'AttendanceType.CLOCK_IN').length;
      int breaks = records
          .where((r) => r['type'] == 'AttendanceType.BREAK_START')
          .length;

      final moods = records
          .where((r) => r['mood'] != null)
          .map((r) => r['mood'] as String)
          .toList();

      return {
        'date': now.toIso8601String(),
        'active_users': activeUsers,
        'clock_ins': clockIns,
        'breaks_taken': breaks,
        'moods': moods,
      };
    } catch (e) {
      debugPrint('❌ Error generating daily summary: $e');
      return {};
    }
  }

  Future<void> sendDailyStandupToAdmins() async {
    try {
      final summary = await generateDailySummary();
      if (summary.isEmpty) return;

      final admins = await getAllAdmins();
      final message = '📊 Daily Stand-up Summary\n'
          'Active Users: ${summary['active_users']}\n'
          'Clock-ins: ${summary['clock_ins']}\n'
          'Breaks: ${summary['breaks_taken']}';

      for (var admin in admins) {
        await sendNotification(
          userId: admin.id,
          title: 'Team Daily Summary',
          body: message,
          data: {'type': 'daily_summary', 'summary': summary},
        );
      }
      debugPrint('✅ Daily summary sent to admins');
    } catch (e) {
      debugPrint('❌ Error sending daily summary: $e');
    }
  }

  // --- Milestone Celebration Bot ---

  Future<void> checkAndBroadcastMilestones() async {
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Birthdays (Format in DB is YYYY-MM-DD or similar, we check MM-DD)
      final profilesResponse = await _supabase.from('profiles').select();
      final List<dynamic> profiles = profilesResponse as List<dynamic>;

      for (var profile in profiles) {
        final birthday = profile['birthday'] as String?;
        final joiningDate = profile['joining_date'] as String?;
        final name = profile['name'] ?? 'Team Member';

        if (birthday != null && birthday.contains(todayStr)) {
          await _broadcastMilestone(
            title: '🎂 Happy Birthday!',
            message: 'Wishing $name a fantastic birthday today! 🎈',
          );
        }

        if (joiningDate != null && joiningDate.contains(todayStr)) {
          final joinYear = DateTime.parse(joiningDate).year;
          final years = now.year - joinYear;
          if (years > 0) {
            await _broadcastMilestone(
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

  Future<void> _broadcastMilestone({
    required String title,
    required String message,
  }) async {
    await sendCustomNotification(title: title, message: message);
  }
}
