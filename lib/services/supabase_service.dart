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
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

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
}
