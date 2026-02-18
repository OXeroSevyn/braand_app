import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../models/user.dart';
import '../glass_container.dart';
import '../user_avatar.dart';

class AttendanceHeader extends StatefulWidget {
  final User user;
  final bool isAdminView;
  final bool isClockedIn;
  final DateTime? clockInTime;
  final VoidCallback onClockToggle;
  final bool isLoading;
  final User? selectedEmployee;
  final List<User> allEmployees;
  final Function(User) onEmployeeSelected;

  const AttendanceHeader({
    super.key,
    required this.user,
    this.isAdminView = false,
    required this.isClockedIn,
    this.clockInTime,
    required this.onClockToggle,
    this.isLoading = false,
    this.selectedEmployee,
    this.allEmployees = const [],
    required this.onEmployeeSelected,
  });

  @override
  State<AttendanceHeader> createState() => _AttendanceHeaderState();
}

class _AttendanceHeaderState extends State<AttendanceHeader>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(AttendanceHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isClockedIn != oldWidget.isClockedIn ||
        widget.clockInTime != oldWidget.clockInTime) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.isClockedIn && widget.clockInTime != null) {
      _updateDuration();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateDuration();
      });
    } else {
      _duration = Duration.zero;
      if (mounted) setState(() {});
    }
  }

  void _updateDuration() {
    if (mounted && widget.clockInTime != null) {
      setState(() {
        _duration = DateTime.now().difference(widget.clockInTime!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        widget.isClockedIn ? Colors.redAccent : AppColors.brand;
    final statusText = widget.isClockedIn ? 'ON DUTY' : 'OFF DUTY';

    return Column(
      children: [
        // App Bar / Title Area
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATTENDANCE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMMM')
                      .format(DateTime.now())
                      .toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            if (widget.isAdminView) _buildAdminUserSelector(isDark),
          ],
        ),
        const SizedBox(height: 24),

        // Main Status Card
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2A2A2A),
                      const Color(0xFF1A1A1A),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF0F0F0),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern or Gradient Blob
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Avatar & Greeting
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          avatarUrl: widget.isAdminView
                              ? (widget.selectedEmployee?.avatar ?? '')
                              : widget.user.avatar,
                          name: widget.isAdminView
                              ? (widget.selectedEmployee?.name ?? '')
                              : widget.user.name,
                          size: 56,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isAdminView
                                    ? (widget.selectedEmployee?.name ??
                                        'Select User')
                                    : 'Hello, ${widget.user.name.split(' ')[0]}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: primaryColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  if (widget.isClockedIn &&
                                      widget.clockInTime != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.timer_outlined,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(_duration),
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Area: Shift Stats / Important Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            width: 1),
                      ),
                      // Quick fix for border logic above
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              context,
                              'START TIME',
                              widget.clockInTime != null
                                  ? DateFormat('hh:mm a')
                                      .format(widget.clockInTime!)
                                  : '--:--',
                              Icons.login),
                          Container(
                              width: 1,
                              height: 30,
                              color: isDark ? Colors.white24 : Colors.black12),
                          _buildStatItem(
                              context,
                              'STATUS',
                              widget.isClockedIn ? 'WORKING' : 'AWAY',
                              widget.isClockedIn
                                  ? Icons.laptop_mac
                                  : Icons.coffee),
                          Container(
                              width: 1,
                              height: 30,
                              color: isDark ? Colors.white24 : Colors.black12),
                          _buildStatItem(
                              context,
                              'DATE',
                              DateFormat('d MMM').format(DateTime.now()),
                              Icons.calendar_today_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminUserSelector(bool isDark) {
    return PopupMenuButton<User>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: GlassContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(50),
        child: const Icon(Icons.people_outline), // Simplified icon
      ),
      itemBuilder: (context) => widget.allEmployees.map((emp) {
        return PopupMenuItem<User>(
          value: emp,
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: emp.avatar,
                name: emp.name,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                emp.name,
                style: GoogleFonts.spaceMono(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: widget.onEmployeeSelected,
    );
  }
}
