import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, Supabase, FileOptions;
import '../models/attendance_record.dart';
import '../models/user.dart' as app_models;
import '../models/report_data.dart';
import 'package:braand_app/models/attendance_stats.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save an attendance record (clock in/out, break start/end)
  Future<void> saveRecord(AttendanceRecord record) async {
    try {
      debugPrint(
          '📡 Saving attendance record: ${record.type} for ${record.userId}');
      await _supabase.from('attendance_records').insert(record.toJson());
      debugPrint('✅ Attendance record saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving attendance record: $e');
      rethrow;
    }
  }

  /// FOR OFFLINE SYNC ONLY: Directly insert pre-formatted data
  Future<void> manualInsertAttendance(Map<String, dynamic> data) async {
    await _supabase.from('attendance_records').insert(data);
  }

  /// Get all attendance records (Admin only)
  Future<List<AttendanceRecord>> getRecords() async {
    try {
      debugPrint('📡 Fetching all attendance records...');
      final response = await _supabase
          .from('attendance_records')
          .select()
          .order('timestamp', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('📡 Received ${data.length} records from DB');
      return data.map((json) => _mapJsonToRecord(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching all records: $e');
      return [];
    }
  }

  /// Get attendance records for a specific user
  Future<List<AttendanceRecord>> getUserRecords(String userId) async {
    try {
      debugPrint('📡 Fetching records for user: $userId');
      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('📡 Received ${data.length} records for user from DB');
      return data.map((json) => _mapJsonToRecord(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching user records: $e');
      return [];
    }
  }

  AttendanceType _parseAttendanceType(String typeStr) {
    if (typeStr.contains('clockIn')) return AttendanceType.clockIn;
    if (typeStr.contains('clockOut')) return AttendanceType.clockOut;
    if (typeStr.contains('breakStart')) return AttendanceType.breakStart;
    if (typeStr.contains('breakEnd')) return AttendanceType.breakEnd;
    return AttendanceType.clockIn;
  }

  AttendanceRecord _mapJsonToRecord(Map<String, dynamic> json) {
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
      deviceId: json['device_id'],
      biometricVerified: json['biometric_verified'] ?? false,
      photoUrl: json['photo_url'],
      verificationMethod: json['verification_method'],
    );
  }

  /// Get user records for a specific date range
  Future<List<AttendanceRecord>> getUserRecordsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startTs = startDate.millisecondsSinceEpoch;
      final endTs = endDate.millisecondsSinceEpoch;

      debugPrint('📡 Fetching records for $userId from $startTs to $endTs');

      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', startTs)
          .lte('timestamp', endTs)
          .order('timestamp', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => _mapJsonToRecord(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching records for date range: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceReport(
      DateTime start, DateTime end) async {
    try {
      final startTs = start.millisecondsSinceEpoch;
      final endTs = end.millisecondsSinceEpoch;

      final response = await _supabase
          .from('attendance_records')
          .select('*, profiles(name, role, department)')
          .gte('timestamp', startTs)
          .lte('timestamp', endTs)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('❌ Error getting attendance report: $e');
      rethrow;
    }
  }

  Future<String?> uploadAttendancePhoto(
      Uint8List bytes, String fileName) async {
    try {
      await _supabase.storage.from('attendance-photos').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url =
          _supabase.storage.from('attendance-photos').getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('❌ Error uploading attendance photo: $e');
      return null;
    }
  }

  /// FOR LEGACY UI: Get attendance report as List<ReportData>
  Future<List<ReportData>> getAttendanceReportLegacy(
      DateTime start, DateTime end) async {
    try {
      // 1. Fetch all active employees
      final responseProfiles = await _supabase
          .from('profiles')
          .select()
          .eq('status', 'active')
          .eq('role', 'Employee');

      final List<dynamic> profilesData = responseProfiles as List<dynamic>;
      final employees =
          profilesData.map((json) => app_models.User.fromJson(json)).toList();

      List<ReportData> reportData = [];
      for (var employee in employees) {
        final records =
            await getUserRecordsForDateRange(employee.id, start, end);
        reportData.add(ReportData(user: employee, records: records));
      }
      return reportData;
    } catch (e) {
      debugPrint('❌ Error in getAttendanceReportLegacy: $e');
      return [];
    }
  }

  /// Check if a user is currently clocked in today (has an unmatched clock-in)
  Future<bool> isUserCurrentlyClockedIn(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startTs = startOfDay.millisecondsSinceEpoch;

      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', startTs)
          .order('timestamp', ascending: false);

      final List<dynamic> records = response as List;
      if (records.isEmpty) return false;

      // Find the latest clockIn/clockOut
      for (var record in records) {
        if (record['type'].toString().contains('clockIn')) return true;
        if (record['type'].toString().contains('clockOut')) return false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking clock-in status: $e');
      return false;
    }
  }

  /// Auto sign-out user and return logs
  Future<Map<String, dynamic>> autoSignOutUser(String userId) async {
    final List<String> logs = [];
    bool signedOut = false;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startTs = startOfDay.millisecondsSinceEpoch;

      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', startTs)
          .order('timestamp', ascending: false);

      final List<dynamic> records = response as List;
      if (records.isEmpty) {
        logs.add('   - No records found for today.');
        return {'signedOut': false, 'logs': logs};
      }

      String? lastType;
      for (var r in records) {
        final t = r['type'].toString();
        if (t.contains('clockIn') || t.contains('clockOut')) {
          lastType = t;
          break;
        }
      }

      if (lastType != null && lastType.contains('clockIn')) {
        // User is still clocked in. Auto sign out at 6:30 PM (or current time if later)
        final signOutTime = DateTime(now.year, now.month, now.day, 18, 30);
        final finalTs = now.isAfter(signOutTime)
            ? now.millisecondsSinceEpoch
            : signOutTime.millisecondsSinceEpoch;

        await _supabase.from('attendance_records').insert({
          'user_id': userId,
          'type': 'AttendanceType.clockOut',
          'timestamp': finalTs,
          'biometric_verified': false,
          'verification_method': 'auto_system',
        });
        logs.add(
            '✅ Auto-clocked out user at ${DateTime.fromMillisecondsSinceEpoch(finalTs)}');
        signedOut = true;
      } else {
        logs.add('   - User already clocked out.');
      }
    } catch (e) {
      logs.add('❌ Error: $e');
    }

    return {'signedOut': signedOut, 'logs': logs};
  }

  /// ADMIN ONLY: Scan ALL active users and auto sign-out anyone still clocked in
  Future<List<String>> autoSignOutAllUsers() async {
    final List<String> globalLogs = [
      '🚀 Starting Global Auto Clock-Out Report - ${DateTime.now()}'
    ];

    try {
      // Get all profiles that are active
      final profiles = await _supabase
          .from('profiles')
          .select('id, name')
          .eq('status', 'active');

      for (var profile in profiles) {
        final name = profile['name'];
        final uid = profile['id'];

        globalLogs.add('👤 Checking $name...');
        final result = await autoSignOutUser(uid);
        globalLogs.addAll(result['logs'] as List<String>);
      }

      globalLogs.add('🏁 Global Auto Clock-Out Complete.');
    } catch (e) {
      globalLogs.add('❌ CRITICAL ERROR in global sign-out: $e');
    }

    return globalLogs;
  }

  /// Get a list of users who are currently signed in (have an unmatched clockIn)
  Future<Map<String, dynamic>> getUsersCurrentlySignedInWithLogs() async {
    final List<String> logs = ['🔍 Scanning for signed-in users...'];
    final List<String> signedInUserIds = [];

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startTs = startOfDay.millisecondsSinceEpoch;

      // 1. Get all active employees
      final profiles = await _supabase
          .from('profiles')
          .select('id, name')
          .eq('status', 'active')
          .eq('role', 'Employee');

      // 2. For each, check their latest attendance record today
      for (var profile in profiles) {
        final uid = profile['id'];
        final name = profile['name'];

        final records = await _supabase
            .from('attendance_records')
            .select()
            .eq('user_id', uid)
            .gte('timestamp', startTs)
            .order('timestamp', ascending: false)
            .limit(1);

        if (records.isNotEmpty) {
          final type = records[0]['type'].toString();
          if (type.contains('clockIn')) {
            signedInUserIds.add(uid);
            logs.add('   ✅ $name is currently IN');
          } else {
            logs.add('   - $name is currently OUT');
          }
        } else {
          logs.add('   - $name has no records today');
        }
      }

      logs.add('📈 Total currently signed in: ${signedInUserIds.length}');
    } catch (e) {
      logs.add('❌ Error: $e');
    }

    return {
      'users': signedInUserIds,
      'logs': logs,
    };
  }

  /// Automatically end breaks that are longer than 1 hour
  Future<List<String>> autoEndStaleBreaks() async {
    final List<String> logs = ['⏳ Checking for stale breaks (>1hr)...'];
    try {
      final employees = await _supabase
          .from('profiles')
          .select('id, name')
          .eq('status', 'active');

      int fixedCount = 0;
      for (var emp in employees) {
        final records = await _supabase
            .from('attendance_records')
            .select()
            .eq('user_id', emp['id'])
            .order('timestamp', ascending: false)
            .limit(1);

        if (records.isNotEmpty) {
          final last = records[0];
          if (last['type'].toString().contains('breakStart')) {
            final startTime =
                DateTime.fromMillisecondsSinceEpoch(last['timestamp']);
            final diff = DateTime.now().difference(startTime);

            if (diff.inMinutes >= 60) {
              // End it
              await _supabase.from('attendance_records').insert({
                'user_id': emp['id'],
                'type': 'AttendanceType.breakEnd',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'biometric_verified': false,
                'verification_method': 'none',
              });
              fixedCount++;
            }
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

  Future<List<String>> getUsersCurrentlySignedIn() async {
    final result = await getUsersCurrentlySignedInWithLogs();
    return List<String>.from(result['users']);
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
      // Note: This still depends on the monthly_tasks table.
      // We might consider moving task stats to a TaskService later.
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
      final startTs = startDate.millisecondsSinceEpoch;
      final endDateForQuery = endDate.add(const Duration(days: 1));
      final endTs = endDateForQuery.millisecondsSinceEpoch;

      final attendanceResponse = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', startTs)
          .lte('timestamp', endTs)
          .order('timestamp');

      final List<dynamic> records = attendanceResponse as List;
      final Set<String> presentDays = {};
      int lateArrivals = 0;

      // Fetch office hours
      final settingsResponse =
          await _supabase.from('office_hours_settings').select().maybeSingle();
      final startHour =
          settingsResponse != null ? settingsResponse['start_hour'] : 9;
      final startMinute =
          settingsResponse != null ? settingsResponse['start_minute'] : 30;

      for (var record in records) {
        if (record['type'].toString().contains('clockIn')) {
          final time = DateTime.fromMillisecondsSinceEpoch(record['timestamp']);
          final dateKey = '${time.year}-${time.month}-${time.day}';
          presentDays.add(dateKey);

          final threshold = DateTime(
            time.year,
            time.month,
            time.day,
            startHour,
            startMinute + 15,
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

      int leaveDays = 0;
      for (var leave in leavesResponse) {
        final start = DateTime.parse(leave['start_date']);
        final end = DateTime.parse(leave['end_date']);

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

  /// Get attendance statistics for a user for a specific month
  Future<AttendanceStats> getAttendanceStats(
      String userId, int month, int year) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0);

      // Fetch records for the month
      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', startOfMonth.millisecondsSinceEpoch)
          .lte('timestamp', endOfMonth.millisecondsSinceEpoch)
          .order('timestamp', ascending: true);

      final records = (response as List)
          .map((json) => _mapJsonToRecord(json as Map<String, dynamic>))
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
          final inTime = settings['in_time'] as String;
          final parts = inTime.split(':');
          officeStart = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        debugPrint('Error fetching office hours for stats: $e');
      }

      int totalDaysPresent = 0;
      int lateDays = 0;
      Duration totalWorkingDuration = Duration.zero;
      final Set<String> uniqueDates = {};

      DateTime? lastClockIn;
      for (var record in records) {
        final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
        final dateKey = '${date.year}-${date.month}-${date.day}';

        if (record.type == AttendanceType.clockIn) {
          if (!uniqueDates.contains(dateKey)) {
            totalDaysPresent++;
            uniqueDates.add(dateKey);

            if (date.hour > officeStart.hour ||
                (date.hour == officeStart.hour &&
                    date.minute > officeStart.minute + 15)) {
              lateDays++;
            }
          }
          lastClockIn = date;
        } else if (record.type == AttendanceType.clockOut &&
            lastClockIn != null) {
          final clockOut =
              DateTime.fromMillisecondsSinceEpoch(record.timestamp);
          if (clockOut.day == lastClockIn.day) {
            totalWorkingDuration += clockOut.difference(lastClockIn);
          }
          lastClockIn = null;
        }
      }

      // Calculate average hours (as double)
      double averageHours = 0.0;
      if (totalDaysPresent > 0) {
        averageHours =
            totalWorkingDuration.inMinutes / (60.0 * totalDaysPresent);
      }

      return AttendanceStats(
        presentDays: totalDaysPresent,
        lateDays: lateDays,
        absentDays: 0, // Simplified or calculate if needed
        averageHours: averageHours,
        totalWorkingDays: totalDaysPresent, // Simplified
      );
    } catch (e) {
      debugPrint('❌ Error getting attendance stats: $e');
      return AttendanceStats.empty();
    }
  }

  /// Generate a daily summary report for admins
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
          records.where((r) => r['type'].toString().contains('clockIn')).length;
      int breaks = records
          .where((r) => r['type'].toString().contains('breakStart'))
          .length;

      return {
        'date': now.toIso8601String(),
        'active_users': activeUsers,
        'clock_ins': clockIns,
        'breaks_taken': breaks,
      };
    } catch (e) {
      debugPrint('❌ Error generating daily summary: $e');
      return {};
    }
  }
}
