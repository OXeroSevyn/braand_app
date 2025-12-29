import 'dart:async';
import 'package:flutter/foundation.dart';
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

  Future<void> _checkAndAutoSignOut() async {
    try {
      final officeHours = await _officeHoursService.checkOfficeHours();

      // If we're outside office hours, auto sign-out all signed-in users
      if (!officeHours.isWithinHours) {
        debugPrint(
            '🕐 Outside office hours, checking for users to auto sign-out');

        final signedInUsers =
            await _supabaseService.getUsersCurrentlySignedIn();

        if (signedInUsers.isNotEmpty) {
          debugPrint('🕐 Found ${signedInUsers.length} users still signed in');

          for (final userId in signedInUsers) {
            await _supabaseService.autoSignOutUser(userId);
          }

          debugPrint('✅ Auto signed out ${signedInUsers.length} users');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in auto sign-out check: $e');
    }
  }
}
