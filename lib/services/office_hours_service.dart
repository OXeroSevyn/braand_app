import 'package:flutter/material.dart';
import 'supabase_service.dart';

class OfficeHoursService {
  final SupabaseService _supabase = SupabaseService();

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

    final settings = await _supabase.getOfficeHours();
    if (settings == null) {
      return OfficeHoursStatus(isWithinHours: true, message: null);
    }

    final inTime = _parseTimeString(settings['in_time']);
    final outTime = _parseTimeString(settings['out_time']);
    final currentTime = TimeOfDay.now();

    final isWithin = _isTimeBetween(currentTime, inTime, outTime);

    if (!isWithin) {
      final inTimeStr = _formatTime(inTime);
      final outTimeStr = _formatTime(outTime);
      return OfficeHoursStatus(
        isWithinHours: false,
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

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes < startMinutes) {
      // Handles overnight shifts (e.g., 10 PM to 6 AM)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
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
  final String? message;
  final TimeOfDay? officeInTime;
  final TimeOfDay? officeOutTime;

  OfficeHoursStatus({
    required this.isWithinHours,
    this.isSundayOff = false,
    this.message,
    this.officeInTime,
    this.officeOutTime,
  });
}
