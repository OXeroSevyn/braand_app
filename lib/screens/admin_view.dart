import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/neo_card.dart';
import '../widgets/user_avatar.dart';
import 'attendance_screen.dart';
import 'messages_screen.dart';
import 'notification_settings_screen.dart';
import 'office_locations_screen.dart';
import 'reports_screen.dart';
import 'admin_tasks_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';
import 'admin_employee_list_screen.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final SupabaseService _supabaseService = SupabaseService();
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _refreshTimer;
  Timer? _unreadCheckTimer;
  List<User> _employees = [];
  List<AttendanceRecord> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
    _startUnreadCheck();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _unreadCheckTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 2 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadData(),
    );
  }

  void _startUnreadCheck() {
    // Check for unread messages every 2 seconds
    _unreadCheckTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (mounted && _currentIndex != 5) {
        // Only check when not on Messages tab
        try {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.user != null) {
            final count = await _supabaseService.getUnreadCount(auth.user!.id);
            if (mounted) {
              setState(() {
                _unreadCount = count;
              });
            }
          }
        } catch (e) {
          debugPrint('Error checking unread count: $e');
        }
      } else if (mounted && _currentIndex == 5) {
        // Clear badge when on Messages tab
        if (_unreadCount > 0) {
          setState(() {
            _unreadCount = 0;
          });
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final emps = await _supabaseService.getAllEmployees();
      final records = await _supabaseService.getRecords();

      if (mounted) {
        setState(() {
          _employees = emps;
          _recentActivity = records.take(20).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
  }

  String _getEmployeeStatus(String userId) {
    // Find the latest record for this user
    try {
      final lastRecord = _recentActivity.firstWhere((r) => r.userId == userId);

      switch (lastRecord.type) {
        case AttendanceType.CLOCK_IN:
        case AttendanceType.BREAK_END:
          return 'ONLINE';
        case AttendanceType.BREAK_START:
          return 'ON BREAK';
        case AttendanceType.CLOCK_OUT:
          return 'OFFLINE';
        default:
          return 'OFFLINE';
      }
    } catch (e) {
      return 'OFFLINE'; // No records found
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _currentIndex == 0
          ? _buildDashboard()
          : _currentIndex == 1
              ? AttendanceScreen(user: user, isAdminView: true)
              : _currentIndex == 2
                  ? const ReportsScreen()
                  : _currentIndex == 3
                      ? const AdminTasksScreen()
                      : _currentIndex == 4
                          ? const AdminEmployeeListScreen()
                          : MessagesScreen(user: user, isAdminView: true),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white : Colors.black,
              width: 2,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppColors.brand,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'DASHBOARD',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'ATTENDANCE',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'REPORTS',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              label: 'TASKS',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'EMPLOYEES',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'MESSAGES',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple Header
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.brand, width: 4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GLOBAL OPS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SYSTEM LIVE',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Office Locations Button
                IconButton(
                  icon: const Icon(Icons.location_on, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OfficeLocationsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Office Locations',
                ),
                // Notification Settings Button
                IconButton(
                  icon: const Icon(Icons.notifications_active, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Notification Settings',
                ),
                // Profile Button
                IconButton(
                  icon: const Icon(Icons.account_circle, size: 28),
                  onPressed: () {
                    final currentUser =
                        Provider.of<AuthProvider>(context, listen: false).user;
                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(user: currentUser),
                        ),
                      );
                    }
                  },
                  tooltip: 'Profile',
                ),
                // User Management Button
                IconButton(
                  icon: const Icon(Icons.manage_accounts, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                  tooltip: 'Manage Users',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          _buildStats(),
          const SizedBox(height: 24),

          // Employee Table
          _buildEmployeeTable(),
          const SizedBox(height: 24),

          // Activity Feed
          _buildActivityFeed(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int totalStaff = _employees.length;
    int onlineCount = 0;
    int onBreakCount = 0;

    for (final emp in _employees) {
      final status = _getEmployeeStatus(emp.id);
      if (status == 'ONLINE') {
        onlineCount++;
      } else if (status == 'ON BREAK') {
        onBreakCount++;
      }
    }

    return Column(
      children: [
        // Total Staff Card
        _buildStatCard(
          'TOTAL STAFF',
          totalStaff,
          isDark ? Colors.white : Colors.black,
          Icons.people,
          isDark,
        ),
        const SizedBox(height: 16),

        // Online Now Card
        _buildStatCard(
          'ONLINE NOW',
          onlineCount,
          AppColors.brand,
          Icons.bolt,
          isDark,
          isHighlight: true,
        ),
        const SizedBox(height: 16),

        // On Break Card
        _buildStatCard(
          'ON BREAK',
          onBreakCount,
          isDark ? Colors.white : Colors.black,
          Icons.coffee,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color borderColor,
    IconData icon,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.brand
            : (isDark ? AppColors.darkSurface : Colors.white),
        border: Border.all(
          color: isDark ? Colors.white : Colors.black,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black : Colors.black,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? Colors.black
                      : (isDark ? Colors.grey : Colors.grey[600]),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isHighlight ? Colors.black : null,
                  height: 1,
                ),
              ),
            ],
          ),
          Icon(
            icon,
            size: 32,
            color: isHighlight
                ? Colors.black
                : (isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work, size: 20),
              const SizedBox(width: 8),
              Text(
                'WORKFORCE STATUS',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table Header
          if (_employees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'EMPLOYEE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'DEPT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'STATUS',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

          if (_employees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'NO EMPLOYEES',
                  style: GoogleFonts.spaceMono(color: Colors.grey),
                ),
              ),
            )
          else
            ..._employees.map((emp) {
              final status = _getEmployeeStatus(emp.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    UserAvatar(
                      avatarUrl: emp.avatar,
                      name: emp.name,
                      size: 36,
                      showBorder: true,
                    ),
                    const SizedBox(width: 12),

                    // Name
                    Expanded(
                      flex: 3,
                      child: Text(
                        emp.name.toLowerCase(),
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Department
                    Expanded(
                      flex: 2,
                      child: Text(
                        emp.department.toLowerCase(),
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    // Status Badge
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 8),
              Text(
                'RECENT ACTIVITY',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentActivity.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'NO ACTIVITY',
                  style: GoogleFonts.spaceMono(color: Colors.grey),
                ),
              ),
            )
          else
            ..._recentActivity.take(10).map((record) {
              final employee = _employees.firstWhere(
                (e) => e.id == record.userId,
                orElse: () => User(
                  id: '',
                  email: '',
                  name: 'Unknown',
                  role: 'employee',
                  department: '',
                ),
              );

              String action = '';
              Color iconColor = Colors.grey;
              IconData iconData = Icons.circle;

              switch (record.type) {
                case AttendanceType.CLOCK_IN:
                  action = 'CLOCKED IN';
                  iconColor = AppColors.brand; // Lime green
                  iconData = Icons.login;
                  break;
                case AttendanceType.CLOCK_OUT:
                  action = 'CLOCKED OUT';
                  iconColor = Colors.red;
                  iconData = Icons.logout;
                  break;
                case AttendanceType.BREAK_START:
                  action = 'BREAK START';
                  iconColor = Colors.purple;
                  iconData = Icons.play_arrow;
                  break;
                case AttendanceType.BREAK_END:
                  action = 'BREAK END';
                  iconColor = Colors.amber;
                  iconData = Icons.stop;
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon box
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor,
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.black,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        size: 16,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(record.timestamp),
                      ),
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        employee.name.toLowerCase(),
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      action,
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
