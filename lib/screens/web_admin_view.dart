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
import 'reports_screen.dart';
import 'admin_tasks_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';
import 'admin_employee_list_screen.dart';
import 'notice_board_screen.dart';

class WebAdminView extends StatefulWidget {
  final int initialIndex;
  const WebAdminView({super.key, this.initialIndex = 0});

  @override
  State<WebAdminView> createState() => _WebAdminViewState();
}

class _WebAdminViewState extends State<WebAdminView> {
  final SupabaseService _supabaseService = SupabaseService();
  late int _currentIndex;
  int _unreadCount = 0;
  Timer? _refreshTimer;
  Timer? _unreadCheckTimer;
  List<User> _employees = [];
  List<AttendanceRecord> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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
      if (mounted && _currentIndex != 5) {
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
      } else if (mounted && _currentIndex == 6) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Widget> screens = [
      _buildDashboard(isDark),
      AttendanceScreen(user: user, isAdminView: true),
      const ReportsScreen(),
      const AdminTasksScreen(),
      const AdminEmployeeListScreen(),
      NoticeBoardScreen(user: user),
      MessagesScreen(user: user, isAdminView: true),
    ];

    return screens[_currentIndex.clamp(0, screens.length - 1)];
  }

  Widget _buildDashboard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildEmployeesCard(),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: _buildRecentActivityCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard(
            'Active Now',
            _employees.where((e) => e.status == 'IN').length.toString(),
            Icons.people,
            Colors.blue),
        const SizedBox(width: 24),
        _buildStatCard(
            'On Break',
            _employees.where((e) => e.status == 'BREAK').length.toString(),
            Icons.coffee,
            Colors.orange),
        const SizedBox(width: 24),
        _buildStatCard(
            'Absent',
            _employees
                .where((e) => e.status == 'OUT' || e.status == 'IDLE')
                .length
                .toString(),
            Icons.person_off,
            Colors.red),
        const SizedBox(width: 24),
        _buildStatCard('Unread', _unreadCount.toString(),
            Icons.mark_email_unread, AppColors.brand),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: NeoCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesCard() {
    return NeoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STAFF MONITOR',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 4),
                  child: const Text('VIEW ALL',
                      style: TextStyle(color: AppColors.brand, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _employees.take(10).length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFF1A1A1A), height: 1),
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    child: Text(emp.name[0],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(emp.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(emp.role,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(emp.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _getStatusColor(emp.status).withOpacity(0.3)),
                    ),
                    child: Text(
                      emp.status,
                      style: TextStyle(
                          color: _getStatusColor(emp.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return NeoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'LIVE ACTIVITY',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          Expanded(
            child: _recentActivity.isEmpty
                ? const Center(
                    child: Text('NO RECENT DATA',
                        style: TextStyle(color: Colors.white24, fontSize: 11)))
                : ListView.separated(
                    itemCount: _recentActivity.take(15).length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFF1A1A1A), height: 1),
                    itemBuilder: (context, index) {
                      final record = _recentActivity[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        title: Text(
                            _employees
                                .firstWhere((e) => e.id == record.userId,
                                    orElse: () => User(
                                        id: '',
                                        name: 'Unknown',
                                        email: '',
                                        role: '',
                                        department: '',
                                        status: ''))
                                .name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${record.type.toString().split('.').last} at ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(record.timestamp))}',
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 10),
                        ),
                        trailing: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN':
      case 'ONLINE':
      case 'ACTIVE':
        return AppColors.brand;
      case 'BREAK':
      case 'ON BREAK':
        return Colors.orange;
      case 'OUT':
      case 'OFFLINE':
      case 'IDLE':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
