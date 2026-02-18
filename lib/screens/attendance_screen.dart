import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';
import '../models/attendance_stats.dart';
import '../services/supabase_service.dart';
import '../services/attendance_verification_service.dart';
import '../services/office_hours_service.dart';
import '../utils/attendance_utils.dart';
import '../widgets/attendance/attendance_header.dart';
import '../widgets/attendance/bento_stats_grid.dart';
import '../widgets/attendance/modern_calendar.dart';
import '../widgets/attendance/gradient_timeline.dart';

class AttendanceScreen extends StatefulWidget {
  final User user;
  final bool isAdminView;

  const AttendanceScreen({
    super.key,
    required this.user,
    this.isAdminView = false,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AttendanceVerificationService _verificationService =
      AttendanceVerificationService();
  final OfficeHoursService _officeHoursService = OfficeHoursService();

  AttendanceStats? _stats;
  List<AttendanceRecord> _allRecords = [];
  List<User> _allEmployees = [];
  User? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;
  bool _isActionLoading = false;

  // Status State
  bool _isClockedIn = false;
  DateTime? _clockInTime;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isAdminView) {
        // Logic for Admin View (fetching employees)
        await _loadEmployeesIfNeeded();
      }

      final targetUserId = widget.isAdminView && _selectedEmployee != null
          ? _selectedEmployee!.id
          : widget.user.id;

      final now = DateTime.now();
      // Fetch 6 months back for scrolling, but focus on current month
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
      final nextMonth = DateTime(
          now.year, now.month + 1, 1); // Fetch slightly ahead just in case

      final records = await _supabaseService.getUserRecordsForDateRange(
        targetUserId,
        sixMonthsAgo,
        nextMonth,
      );

      final stats = await _supabaseService.getAttendanceStats(
        targetUserId,
        _currentMonth.year,
        _currentMonth.month,
      );

      // Determine Status from latest record
      _determineStatus(records);

      if (mounted) {
        setState(() {
          _allRecords = records;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEmployeesIfNeeded() async {
    if (_allEmployees.isNotEmpty) return;
    try {
      final employees = await _supabaseService.getAllEmployees();
      if (mounted) {
        setState(() {
          _allEmployees = employees;
          if (employees.isNotEmpty && _selectedEmployee == null) {
            _selectedEmployee = employees.first; // Default to first
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }

  void _determineStatus(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      _isClockedIn = false;
      _clockInTime = null;
      return;
    }

    // Sort to ensure we have latest first (Supabase usually returns this way but verify)
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latest = records.first;

    if (latest.type == AttendanceType.CLOCK_IN ||
        latest.type == AttendanceType.BREAK_END) {
      final latestTime = DateTime.fromMillisecondsSinceEpoch(latest.timestamp);
      final now = DateTime.now();

      // Check if the clock-in is from TODAY.
      // If it's from a previous day, assume they forgot to clock out and mark as OFF DUTY for today.
      final isToday = latestTime.year == now.year &&
          latestTime.month == now.month &&
          latestTime.day == now.day;

      if (isToday) {
        _isClockedIn = true;
        _clockInTime = latestTime;
      } else {
        _isClockedIn = false;
        _clockInTime = null;
      }
    } else {
      _isClockedIn = false;
      _clockInTime = null;
    }
  }

  Future<void> _handleClockToggle() async {
    if (widget.isAdminView) return;

    setState(() => _isActionLoading = true);

    final type =
        _isClockedIn ? AttendanceType.CLOCK_OUT : AttendanceType.CLOCK_IN;

    try {
      // 1. Parallel Checks (Office Hours & Office Location Check hidden in verification)
      // Since verification calls location which triggers DB, we optimistically assume success for UI
      // if we wanted super speed, but we MUST verify location before allowing logic.
      // However, we can optimize by just running checks.

      final officeHoursStatus = await _officeHoursService.checkOfficeHours();

      if (!officeHoursStatus.isWithinHours) {
        if (mounted) {
          setState(() => _isActionLoading = false);
          _showErrorDialog(officeHoursStatus.message ?? 'Outside office hours');
        }
        return;
      }

      // 2. Verification (Includes Location Check)
      final verificationResult = await _verificationService.verifyAttendance(
        userId: widget.user.id,
        type: type,
        requirePhoto: false,
      );

      if (!verificationResult.success) {
        if (mounted) {
          setState(() => _isActionLoading = false);
          _showErrorDialog(
              verificationResult.errorMessage ?? 'Verification failed');
        }
        return;
      }

      // 3. Location (Get cached or recent)
      // verifyAttendance already did the heavy lifting for location check.
      // We just need a coordinate for the record.
      Location? location;
      try {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          location = Location(lat: pos.latitude, lng: pos.longitude);
        } else {
          // Fallback if needed, but verifyAttendance implies we found a location
          final fresh = await Geolocator.getCurrentPosition();
          location = Location(lat: fresh.latitude, lng: fresh.longitude);
        }
      } catch (e) {
        debugPrint('Location error for record: $e');
      }

      // 4. Optimistic UI Update
      // Create record locally and update state immediately
      final newRecord = AttendanceRecord(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temp ID
        userId: widget.user.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: type,
        location: location,
        deviceId: verificationResult.deviceId,
        biometricVerified: verificationResult.biometricVerified,
        photoUrl: verificationResult.photoUrl,
        verificationMethod: verificationResult.verificationMethod,
      );

      setState(() {
        _isClockedIn = (type == AttendanceType.CLOCK_IN);
        if (_isClockedIn) {
          _clockInTime =
              DateTime.fromMillisecondsSinceEpoch(newRecord.timestamp);
        } else {
          _clockInTime = null;
        }

        // Add to local list so UI reflects it immediately
        _allRecords.insert(0, newRecord);
        _isActionLoading = false; // Stop spinner immediately
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${type == AttendanceType.CLOCK_IN ? 'Clocked In' : 'Clocked Out'} Successfully!'),
          backgroundColor: AppColors.brand,
          duration: const Duration(milliseconds: 1500),
        ));
      }

      // 5. Save & Verify Background (Fire and forget from UI perspective)
      // We save to DB, then silently reload to confirm and replace temp ID
      _supabaseService.saveRecord(newRecord).then((_) {
        // Sync full data in background to ensure consistency
        _loadAttendanceData();
      }).catchError((e) {
        // If save fails, we must revert UI
        if (mounted) {
          setState(() {
            _allRecords.removeWhere((r) => r.id == newRecord.id);
            // Revert status
            _determineStatus(_allRecords);
            _isActionLoading = false;
          });
          _showErrorDialog('Failed to save attendance: $e');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        _showErrorDialog('Error: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Action Failed',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message, style: GoogleFonts.spaceMono(fontSize: 14)),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Determine current month's total hours for the Timeline header?
    // Wait, GradientTimeline takes totalHours for the *selected day*.
    final dailyHours =
        AttendanceUtils.calculateTotalHours(_allRecords, _selectedDate);

    return RefreshIndicator(
      onRefresh: _loadAttendanceData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AttendanceHeader(
              user: widget.user,
              isAdminView: widget.isAdminView,
              isClockedIn: _isClockedIn,
              clockInTime: _clockInTime,
              onClockToggle: _handleClockToggle,
              isLoading: _isActionLoading,
              selectedEmployee: _selectedEmployee,
              allEmployees: _allEmployees,
              onEmployeeSelected: (user) {
                setState(() => _selectedEmployee = user);
                _loadAttendanceData();
              },
            ),
            const SizedBox(height: 32),

            BentoStatsGrid(stats: _stats),
            const SizedBox(height: 32),

            ModernCalendar(
              currentMonth: _currentMonth,
              selectedDate: _selectedDate,
              records: _allRecords,
              onDateSelected: (date) => setState(() => _selectedDate = date),
              onMonthChanged: (date) {
                setState(() {
                  _currentMonth = date;
                  _selectedDate =
                      date; // Create logic to select first day or keep day
                });
                _loadAttendanceData();
              },
            ),
            const SizedBox(height: 40),

            GradientTimeline(
              records: _allRecords,
              selectedDate: _selectedDate,
              totalHours: dailyHours,
            ),
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }
}
