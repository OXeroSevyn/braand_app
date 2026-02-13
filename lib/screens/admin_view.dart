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
import 'office_hours_settings_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';
import 'admin_employee_list_screen.dart';
import 'notice_board_screen.dart';
import 'admin_leave_screen.dart';
import 'admin_release_screen.dart';

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
      if (mounted && _currentIndex != 3) {
        // Only check when not on Messages tab (index 3)
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
                  ? const AdminLeaveScreen()
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
              icon: Icon(Icons.flight_takeoff),
              label: 'LEAVES',
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
    final user = Provider.of<AuthProvider>(context).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Clean Header
          Row(
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
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SYSTEM LIVE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Profile Picture
              GestureDetector(
                onTap: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(user: user),
                      ),
                    );
                  }
                },
                child: UserAvatar(
                  avatarUrl: user?.avatar ?? '',
                  name: user?.name ?? 'Admin',
                  size: 48,
                  showBorder: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Quick Actions Grid
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(),
          const SizedBox(height: 32),

          // 3. Compact Stats
          _buildStats(),
          const SizedBox(height: 24),

          // 4. Employee Table
          _buildEmployeeTable(),
          const SizedBox(height: 24),

          // 5. Activity Feed
          _buildActivityFeed(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = [
      {
        'icon': Icons.people,
        'label': 'EMPLOYEES',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminEmployeeListScreen())),
      },
      {
        'icon': Icons.manage_accounts,
        'label': 'ACCESS',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UserManagementScreen())),
      },
      {
        'icon': Icons.analytics,
        'label': 'INSIGHTS',
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const InsightsScreen())),
      },
      {
        'icon': Icons.assignment,
        'label': 'NOTICES',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NoticeBoardScreen(
                      user: Provider.of<AuthProvider>(context, listen: false)
                          .user!,
                    ))),
      },
      {
        'icon': Icons.location_on,
        'label': 'LOCATIONS',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const OfficeLocationsScreen())),
      },
      {
        'icon': Icons.access_time,
        'label': 'SHIFTS',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const OfficeHoursSettingsScreen())),
      },
      {
        'icon': Icons.rocket_launch,
        'label': 'RELEASES',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminReleaseScreen())),
      },
      {
        'icon': Icons.notifications_active,
        'label': 'ALERTS',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen())),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 Columns for cleaner look
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85, // Taller for text
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: action['onTap'] as VoidCallback,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      size: 24,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['label'] as String,
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

    return Row(
      children: [
        // Total Staff Card
        Expanded(
          child: _buildStatCard(
            'TOTAL\nSTAFF',
            totalStaff,
            isDark ? Colors.white : Colors.black,
            Icons.people,
            isDark,
          ),
        ),
        const SizedBox(width: 12),

        // Online Now Card
        Expanded(
          child: _buildStatCard(
            'ONLINE\nNOW',
            onlineCount,
            AppColors.brand,
            Icons.bolt,
            isDark,
            isHighlight: true,
          ),
        ),
        const SizedBox(width: 12),

        // On Break Card
        Expanded(
          child: _buildStatCard(
            'ON\nBREAK',
            onBreakCount,
            isDark ? Colors.white : Colors.black,
            Icons.coffee,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color borderColor, // Kept for API signature, used as accent
    IconData icon,
    bool isDark, {
    bool isHighlight = false,
  }) {
    final cardColor = isHighlight
        ? AppColors.brand
        : (isDark ? AppColors.darkSurface : Colors.white);

    // For highlighted card, text should be black. For dark mode card, text white.
    final textColor =
        isHighlight ? Colors.black : (isDark ? Colors.white : Colors.black);
    final labelColor =
        isHighlight ? Colors.black.withOpacity(0.7) : Colors.grey;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        // Removed heavy shadow for cleaner look
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  height: 1.2,
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: textColor.withOpacity(0.5),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1,
            ),
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
                        borderRadius: BorderRadius.circular(8), // Rounded
                        // Removed hard border
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
