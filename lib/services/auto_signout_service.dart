import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'office_hours_service.dart';
import '../models/attendance_record.dart';

/// Background service to auto sign-out employees at office closing time
class AutoSignOutService {
  final SupabaseService _supabaseService = SupabaseService();
  final OfficeHoursService _officeHoursService = OfficeHoursService();
  Timer? _checkTimer;

  /// Start the auto sign-out checker
  /// Checks every minute if it's past office hours and auto signs out users
  void start() {
    debugPrint('🕐 Auto sign-out service started');

    // Check immediately
    _checkAndAutoSignOut();

    // Then check every minute
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndAutoSignOut();
    });
  }

  /// Stop the auto sign-out service
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    debugPrint('🕐 Auto sign-out service stopped');
  }

  /// Manually trigger check and return detailed report
  Future<List<String>> triggerNow() async {
    debugPrint('👉 Manual trigger of auto sign-out check');
    return await _checkAndAutoSignOut();
  }

  Future<List<String>> _checkAndAutoSignOut() async {
    List<String> executionLogs = [];
    executionLogs.add('🕐 Starting Auto Sign-Out Check at ${DateTime.now()}');

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        executionLogs.add('ℹ️ No user currently logged in. Skipping.');
        return executionLogs;
      }

      final officeHours = await _officeHoursService.checkOfficeHours();
      executionLogs.add('🏢 Office Hours Status:');
      executionLogs.add('   - Within Hours: ${officeHours.isWithinHours}');
      executionLogs.add('   - Is After Hours: ${officeHours.isAfterHours}');

      // always check stale breaks
      final breakLogs = await _supabaseService.autoEndStaleBreaks();
      executionLogs.addAll(breakLogs);

      if (!officeHours.isWithinHours && officeHours.isAfterHours) {
        executionLogs.add('🚀 TRIGGERED: It is strictly after hours.');

        // 1. Check if CURRENT user is an ADMIN
        // We need to fetch the profile to know the role
        final userProfile = await _supabaseService.getUserProfile(user.id);

        if (userProfile != null && userProfile.role == 'Admin') {
          executionLogs
              .add('👮 Current user is ADMIN. Initiating Global Cleanup...');
          final globalLogs = await _supabaseService.autoSignOutAllUsers();
          executionLogs.addAll(globalLogs);
        }

        // 2. ALWAYS Check current user Status (Self-Cleanup)
        executionLogs.add('👤 Checking local user status...');

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final records = await _supabaseService.getUserRecordsForDateRange(
          user.id,
          todayStart,
          todayEnd,
        );

        final clockIns =
            records.where((r) => r.type == AttendanceType.CLOCK_IN).toList();
        final clockOuts =
            records.where((r) => r.type == AttendanceType.CLOCK_OUT).toList();

        if (clockIns.isNotEmpty && clockOuts.length < clockIns.length) {
          executionLogs.add(
              '   - ⚠️ Current user is still Clocked In. auto-signing out...');

          // Database Clock Out
          await _supabaseService.autoSignOutUser(user.id);
          executionLogs.add('   - ✅ Database record updated.');

          // Local Auth Logout
          debugPrint('👋 Performing local logout for auto sign-out...');
          await Supabase.instance.client.auth.signOut();
          executionLogs.add('   - ✅ Local session cleared. User logged out.');
        } else {
          executionLogs.add('   - ✅ User is already clocked out.');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in auto sign-out check: $e');
      executionLogs.add('❌ EXCEPTION: $e');
    }
    return executionLogs;
  }
}
