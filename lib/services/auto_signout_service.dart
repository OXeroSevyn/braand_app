import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'office_hours_service.dart';

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
      // NOTE: We do not strictly check for Supabase.instance.client.auth.currentUser
      // because we want this service to ATTEMPT to run if the app is open.
      // RLS policies might still block it if no one is logged in, but we shouldn't abort proactively.

      final officeHours = await _officeHoursService.checkOfficeHours();
      executionLogs.add('🏢 Office Hours Status:');
      executionLogs.add('   - Within Hours: ${officeHours.isWithinHours}');
      executionLogs.add('   - Is After Hours: ${officeHours.isAfterHours}');

      if (officeHours.isBeforeHours)
        executionLogs.add('   - 🕒 Current time is BEFORE office hours');
      if (officeHours.isWithinHours)
        executionLogs.add('   - 🕒 Current time is WITHIN office hours');

      // --- NEW: ALWAYS Check for stale breaks (run every time) ---
      final breakLogs = await _supabaseService.autoEndStaleBreaks();
      executionLogs.addAll(breakLogs);

      // If we're outside office hours AND strictly AFTER hours, auto sign-out
      if (!officeHours.isWithinHours && officeHours.isAfterHours) {
        debugPrint(
            '🕐 After office hours, checking for users to auto sign-out');
        executionLogs
            .add('🚀 TRIGGERED: It is strictly after hours. Scanning users...');

        final result =
            await _supabaseService.getUsersCurrentlySignedInWithLogs();
        final signedInUsers = result['users'] as List<String>;
        final scanLogs = result['logs'] as List<String>;
        executionLogs.addAll(scanLogs);

        if (signedInUsers.isNotEmpty) {
          debugPrint('🕐 Found ${signedInUsers.length} users still signed in');

          for (final userId in signedInUsers) {
            final userLogs = await _supabaseService.autoSignOutUser(userId);
            executionLogs.addAll(userLogs);
          }

          debugPrint('✅ Auto signed out ${signedInUsers.length} users');
          executionLogs.add(
              '✅ OPERATION COMPLETE: Processed ${signedInUsers.length} users.');
        } else {
          executionLogs.add('ℹ️ No users found signed in.');
        }
      } else {
        // Reduced noise logging
        // executionLogs.add('⏸️ SKIPPED: Not strictly after hours yet.');
      }
    } catch (e) {
      debugPrint('❌ Error in auto sign-out check: $e');
      executionLogs.add('❌ EXCEPTION: $e');
    }
    return executionLogs;
  }
}
