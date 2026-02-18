import 'package:flutter/material.dart';
import 'supabase_service.dart';

class OfficeHoursService {
  final SupabaseService _supabase = SupabaseService();

  // Cache
  Map<String, dynamic>? _cachedSettings;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Check if current time is within office hours
  Future<OfficeHoursStatus> checkOfficeHours() async {
    final now = DateTime.now();

    // Check if Sunday
    if (now.weekday == DateTime.sunday) {
      return OfficeHoursStatus(
        isWithinHours: false,
        isSundayOff: true,
        message: 'Office is closed on Sundays',
      );
    }

    // Use Cache if fresh
    Map<String, dynamic>? settings;
    if (_cachedSettings != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheDuration) {
      settings = _cachedSettings;
    } else {
      settings = await _supabase.getOfficeHours();
      if (settings != null) {
        _cachedSettings = settings;
        _lastFetchTime = now;
      }
    }

    if (settings == null) {
      return OfficeHoursStatus(isWithinHours: true, message: null);
    }

    final inTime = _parseTimeString(settings['in_time']);
    final outTime = _parseTimeString(settings['out_time']);
    final currentTime = TimeOfDay.now();

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final inMinutes = inTime.hour * 60 + inTime.minute;
    final outMinutes = outTime.hour * 60 + outTime.minute;

    bool isWithin = false;
    bool isBefore = false;
    bool isAfter = false;

    if (outMinutes < inMinutes) {
      // Overnight shift (e.g. 10 PM to 6 AM)
      isWithin = currentMinutes >= inMinutes || currentMinutes <= outMinutes;

      if (!isWithin) {
        // Outside shift hours (e.g. 12 PM)
        // If we consider the "day" starting at inTime previous day...
        // Basically if it's > outMinutes and < inMinutes, it's "between shifts"
        // We can treat this as "After" the previous shift (or Before next).
        // For auto-signout purposes, we just need to know it's NOT within.
        // But to be precise:
        isAfter = currentMinutes > outMinutes && currentMinutes < inMinutes;
      }
    } else {
      // Standard shift (e.g. 9 AM to 6 PM)
      isWithin = currentMinutes >= inMinutes && currentMinutes <= outMinutes;
      isBefore = currentMinutes < inMinutes;
      isAfter = currentMinutes > outMinutes;
    }

    if (!isWithin) {
      final inTimeStr = _formatTime(inTime);
      final outTimeStr = _formatTime(outTime);
      return OfficeHoursStatus(
        isWithinHours: false,
        isBeforeHours: isBefore,
        isAfterHours: isAfter,
        message: 'Office hours are $inTimeStr to $outTimeStr',
        officeInTime: inTime,
        officeOutTime: outTime,
      );
    }

    return OfficeHoursStatus(
      isWithinHours: true,
      officeInTime: inTime,
      officeOutTime: outTime,
    );
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class OfficeHoursStatus {
  final bool isWithinHours;
  final bool isSundayOff;
  final bool isBeforeHours;
  final bool isAfterHours;
  final String? message;
  final TimeOfDay? officeInTime;
  final TimeOfDay? officeOutTime;

  OfficeHoursStatus({
    required this.isWithinHours,
    this.isSundayOff = false,
    this.isBeforeHours = false,
    this.isAfterHours = false,
    this.message,
    this.officeInTime,
    this.officeOutTime,
  });
}
