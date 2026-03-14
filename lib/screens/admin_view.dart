import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animations/animations.dart';
import '../widgets/continuous_banner.dart';
import '../widgets/employee_carousel.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/neo_card.dart';
import '../widgets/user_avatar.dart';
import '../widgets/dock.dart';
import 'attendance_screen.dart';
import 'messages_screen.dart';
import 'notification_settings_screen.dart';
import 'office_locations_screen.dart';
import 'office_hours_settings_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';
import 'admin_employee_list_screen.dart';
import 'admin_leave_screen.dart';
import 'notice_board_screen.dart';
import 'admin_release_screen.dart';
import 'leaderboard_screen.dart';
import 'admin_performance_screen.dart';

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
  List<Map<String, String>> _notices = [];
  Map<String, dynamic> _dailySummary = {};

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
    // Auto-refresh every 30 seconds to prevent ANR
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadData(),
    );
  }

  void _startUnreadCheck() {
    // Check for unread messages every 30 seconds
    _unreadCheckTimer = Timer.periodic(const Duration(seconds: 30), (
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
      final moods = await _supabaseService.getAggregatedMoods();
      final noticesRaw = await _supabaseService.getNotices();
      final summary = await _supabaseService.generateDailySummary();

      _checkAutomatedTasks();

      final notices = noticesRaw
          .map((n) => {
                'title': n.title,
                'category': n.priority == 'HIGH' ? 'URGENT' : 'NEWS',
              })
          .toList();

      if (mounted) {
        setState(() {
          _employees = emps;
          _recentActivity = records.take(20).toList();
          _notices = notices;
          _dailySummary = summary;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
  }

  Future<void> _checkAutomatedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastRun = prefs.getString('last_admin_auto_run');

      if (lastRun != today) {
        debugPrint('🤖 Triggering automated daily tasks...');
        await _supabaseService.checkAndBroadcastMilestones();
        await _supabaseService.sendDailyStandupToAdmins();
        await prefs.setString('last_admin_auto_run', today);
      }
    } catch (e) {
      debugPrint('Error running automated tasks: $e');
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

  Widget _buildHeader(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand, width: 2),
            ),
            child: UserAvatar(
              avatarUrl: user.avatar,
              name: user.name,
              size: 56,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Terminal',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  user.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SYSTEM OPS',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          PageTransitionSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                fillColor: Colors.transparent,
                child: child,
              );
            },
            child: IndexedStack(
              key: ValueKey<int>(_currentIndex),
              index: _currentIndex,
              children: [
                _buildDashboard(),
                AttendanceScreen(user: user, isAdminView: true),
                const LeaderboardScreen(),
                const AdminLeaveScreen(),
                MessagesScreen(user: user, isAdminView: true),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Dock(
                items: [
                  DockIconData(
                    icon: Icons.dashboard_rounded,
                    label: 'Home',
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  DockIconData(
                    icon: Icons.people_rounded,
                    label: 'Staff',
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  DockIconData(
                    icon: Icons.assignment_rounded,
                    label: 'Reports',
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  DockIconData(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ],
                currentIndex: _currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final user = Provider.of<AuthProvider>(context).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(user),
          ContinuousBanner(isDark: isDark),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats
                _buildStats(),
                const SizedBox(height: 24),
                if (_dailySummary.isNotEmpty) ...[
                  _buildDailySummaryCard(),
                  const SizedBox(height: 24),
                ],
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

                // Quick Stats Bar
                _buildStats(),
                const SizedBox(height: 32),

                // Content Rows
                // 4. Employee Table
                _buildEmployeeTable(),
                const SizedBox(height: 24),

                // 5. Activity Feed
                _buildActivityFeed(),
                const SizedBox(height: 100), // Spacing for Dock
              ],
            ),
          ),
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
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen()),
          );
          // Refresh data including banner when returning
          if (mounted) {
            _loadData(); // This refreshes admin data
            // We need a way to refresh the banner specifically or ensure build is called
            setState(() {
              // Trigger rebuild to refresh banner
            });
          }
        },
      },
      {
        'icon': Icons.speed,
        'label': 'PERFORMANCE',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminPerformanceScreen())),
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
    return EmployeeTable(
      employees: _employees,
      getStatus: _getEmployeeStatus,
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

  Widget _buildDailySummaryCard() {
    final int active = _dailySummary['active_users'] ?? 0;
    final int clockIns = _dailySummary['clock_ins'] ?? 0;
    final int breaks = _dailySummary['breaks_taken'] ?? 0;

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.summarize, size: 20, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY STAND-UP',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AUTOMATED',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  'ACTIVE', active.toString(), Icons.people_outline),
              _buildSummaryItem('IN', clockIns.toString(), Icons.login),
              _buildSummaryItem(
                  'BREAKS', breaks.toString(), Icons.coffee_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep up the great work! System is running at peak multi-core efficiency.',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 8,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
