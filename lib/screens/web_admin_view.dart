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
import '../providers/theme_provider.dart';
import '../widgets/neo_card.dart';
import 'attendance_screen.dart';
import 'messages_screen.dart';
import 'notification_settings_screen.dart';
import 'office_locations_screen.dart';
import 'reports_screen.dart';
import 'admin_tasks_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';

class WebAdminView extends StatefulWidget {
  const WebAdminView({super.key});

  @override
  State<WebAdminView> createState() => _WebAdminViewState();
}

class _WebAdminViewState extends State<WebAdminView> {
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
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadData(),
    );
  }

  void _startUnreadCheck() {
    _unreadCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mounted && _currentIndex != 3) {
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
      } else if (mounted && _currentIndex == 3) {
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
      }
    } catch (e) {
      return 'OFFLINE';
    }
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading:
                    const Icon(Icons.manage_accounts, color: AppColors.brand),
                title: Text(
                  'User Management',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.account_circle, color: AppColors.brand),
                title: Text(
                  'Profile',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final currentUser =
                      Provider.of<AuthProvider>(context, listen: false).user;
                  if (currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(user: currentUser),
                      ),
                    );
                  }
                },
              ),
              Consumer<ThemeProvider>(
                builder: (context, theme, _) => ListTile(
                  leading: Icon(
                    theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: AppColors.brand,
                  ),
                  title: Text(
                    theme.isDarkMode ? 'Light Mode' : 'Dark Mode',
                    style:
                        GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    theme.toggleTheme();
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Logout',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      _buildDashboard(isDark),
      AttendanceScreen(user: user, isAdminView: true),
      const ReportsScreen(),
      MessagesScreen(user: user, isAdminView: true),
      const AdminTasksScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: _unreadCount > 0
                ? Badge(
                    label: Text('$_unreadCount'),
                    child: const Icon(Icons.message),
                  )
                : const Icon(Icons.message),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildStats(isDark),
          const SizedBox(height: 24),
          _buildEmployeeTable(isDark),
          const SizedBox(height: 24),
          _buildRecentActivity(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GLOBAL OPS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Admin Dashboard',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OfficeLocationsScreen()),
              ),
              icon: const Icon(Icons.location_on),
              tooltip: 'Office Locations',
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
              icon: const Icon(Icons.notifications),
              tooltip: 'Notification Settings',
            ),
            IconButton(
              onPressed: () {
                final currentUser =
                    Provider.of<AuthProvider>(context, listen: false).user;
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: currentUser),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.account_circle),
              tooltip: 'Profile',
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              ),
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Manage Users',
            ),
            if (MediaQuery.of(context).size.width < 800)
              IconButton(
                onPressed: _showMobileMenu,
                icon: const Icon(Icons.menu),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(bool isDark) {
    int totalStaff = _employees.length;
    int onlineCount =
        _employees.where((e) => _getEmployeeStatus(e.id) == 'ONLINE').length;
    int onBreakCount =
        _employees.where((e) => _getEmployeeStatus(e.id) == 'ON BREAK').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
              'TOTAL STAFF', totalStaff.toString(), Icons.people, isDark),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
              'ONLINE NOW', onlineCount.toString(), Icons.bolt, isDark,
              isHighlight: true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
              'ON BREAK', onBreakCount.toString(), Icons.coffee, isDark),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark,
      {bool isHighlight = false}) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: isHighlight ? Colors.white : null),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isHighlight ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable(bool isDark) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKFORCE STATUS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_employees.isEmpty)
            const Center(child: Text('No employees found'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _employees.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final emp = _employees[index];
                final status = _getEmployeeStatus(emp.id);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brand,
                    child: Text(
                      emp.name[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    emp.name,
                    style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(emp.department),
                  trailing: _buildStatusBadge(status, isDark),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color;
    switch (status) {
      case 'ONLINE':
        color = AppColors.brand;
        break;
      case 'ON BREAK':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        border:
            Border.all(color: isDark ? Colors.white : Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black : Colors.black,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT ACTIVITY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            const Center(child: Text('No activity yet'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivity.take(10).length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final record = _recentActivity[index];
                final emp = _employees.firstWhere(
                  (e) => e.id == record.userId,
                  orElse: () => User(
                    id: '',
                    email: '',
                    name: 'Unknown',
                    role: '',
                    department: '',
                  ),
                );

                return ListTile(
                  leading: Icon(_getActivityIcon(record.type)),
                  title: Text(
                    emp.name,
                    style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_getActivityText(record.type)),
                  trailing: Text(
                    DateFormat('HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(record.timestamp),
                    ),
                    style: GoogleFonts.spaceMono(fontSize: 12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return Icons.login;
      case AttendanceType.CLOCK_OUT:
        return Icons.logout;
      case AttendanceType.BREAK_START:
        return Icons.pause;
      case AttendanceType.BREAK_END:
        return Icons.play_arrow;
    }
  }

  String _getActivityText(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return 'Clocked in';
      case AttendanceType.CLOCK_OUT:
        return 'Clocked out';
      case AttendanceType.BREAK_START:
        return 'Started break';
      case AttendanceType.BREAK_END:
        return 'Ended break';
    }
  }
}
