import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';
import '../services/supabase_service.dart';
import '../widgets/clock_widget.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import 'attendance_screen.dart';
import '../widgets/location_status_widget.dart';
import 'messages_screen.dart';
import 'employee_tasks_screen.dart';
import 'profile_screen.dart';

class WebEmployeeView extends StatefulWidget {
  final User user;
  const WebEmployeeView({super.key, required this.user});

  @override
  State<WebEmployeeView> createState() => _WebEmployeeViewState();
}

class _WebEmployeeViewState extends State<WebEmployeeView> {
  final SupabaseService _supabaseService = SupabaseService();

  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _refreshTimer;
  Timer? _unreadCheckTimer;
  List<AttendanceRecord> _records = [];
  String _status = 'IDLE';
  AttendanceType? _loadingType;

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
      const Duration(seconds: 5),
      (_) => _loadData(),
    );
  }

  void _startUnreadCheck() {
    _unreadCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mounted && _currentIndex != 2) {
        try {
          final count = await _supabaseService.getUnreadCount(widget.user.id);
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
          }
        } catch (e) {
          debugPrint('Error checking unread count: $e');
        }
      } else if (mounted && _currentIndex == 2) {
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
      final userRecords = await _supabaseService.getUserRecords(widget.user.id);
      if (mounted) {
        setState(() {
          _records = userRecords;
          _determineStatus(userRecords);
        });
      }
    } catch (e) {
      debugPrint('Error loading employee data: $e');
    }
  }

  void _determineStatus(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      _status = 'IDLE';
      return;
    }
    final latest = records.first;
    switch (latest.type) {
      case AttendanceType.CLOCK_IN:
      case AttendanceType.BREAK_END:
        _status = 'ACTIVE';
        break;
      case AttendanceType.BREAK_START:
        _status = 'ON_BREAK';
        break;
      case AttendanceType.CLOCK_OUT:
        _status = 'COMPLETED';
        break;
    }
  }

  Future<void> _handleAttendance(AttendanceType type) async {
    setState(() => _loadingType = type);
    try {
      // Simplified web flow
      Location? location;
      try {
        final pos = await Geolocator.getCurrentPosition();
        location = Location(lat: pos.latitude, lng: pos.longitude);
      } catch (e) {
        debugPrint('Location error: $e');
      }

      final record = AttendanceRecord(
        id: '',
        userId: widget.user.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: type,
        location: location,
        deviceId: 'web-client',
        biometricVerified: false,
        verificationMethod: 'web',
      );

      await _supabaseService.saveRecord(record);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${type.toString().split('.').last} successful')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingType = null);
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

    final List<Widget> screens = [
      _buildDashboard(isDark),
      AttendanceScreen(user: widget.user),
      MessagesScreen(user: widget.user),
      EmployeeTasksScreen(user: widget.user),
      ProfileScreen(user: widget.user),
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
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
          _buildHeader(),
          const SizedBox(height: 24),
          _buildActions(isDark),
          const SizedBox(height: 24),
          _buildCharts(isDark),
          const SizedBox(height: 24),
          _buildRecentLogs(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMPLOYEE PORTAL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.user.name,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            ClockWidget(),
            if (MediaQuery.of(context).size.width < 800) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _showMobileMenu,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brand.withOpacity(0.1),
                  foregroundColor: AppColors.brand,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIONS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              LocationStatusWidget(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeoButton(
                  text: 'CLOCK IN',
                  onPressed: _status == 'IDLE' || _status == 'COMPLETED'
                      ? () => _handleAttendance(AttendanceType.CLOCK_IN)
                      : null,
                  isLoading: _loadingType == AttendanceType.CLOCK_IN,
                  icon: const Icon(Icons.login, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeoButton(
                  text: 'CLOCK OUT',
                  onPressed: _status == 'ACTIVE' || _status == 'ON_BREAK'
                      ? () => _handleAttendance(AttendanceType.CLOCK_OUT)
                      : null,
                  isLoading: _loadingType == AttendanceType.CLOCK_OUT,
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeoButton(
                  text: 'BREAK START',
                  onPressed: _status == 'ACTIVE'
                      ? () => _handleAttendance(AttendanceType.BREAK_START)
                      : null,
                  isLoading: _loadingType == AttendanceType.BREAK_START,
                  icon: const Icon(Icons.coffee, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeoButton(
                  text: 'BREAK END',
                  onPressed: _status == 'ON_BREAK'
                      ? () => _handleAttendance(AttendanceType.BREAK_END)
                      : null,
                  isLoading: _loadingType == AttendanceType.BREAK_END,
                  icon: const Icon(Icons.work, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(bool isDark) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY ACTIVITY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          [
                            'M',
                            'T',
                            'W',
                            'T',
                            'F',
                            'S',
                            'S'
                          ][value.toInt() % 7],
                          style: GoogleFonts.spaceMono(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (index + 2).toDouble(),
                        color: AppColors.brand,
                        width: 20,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs(bool isDark) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT LOGS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_records.isEmpty)
            const Center(child: Text('No activity yet'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _records.take(5).length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final record = _records[index];
                return ListTile(
                  leading: Icon(_getActivityIcon(record.type)),
                  title: Text(
                    _getActivityText(record.type),
                    style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    DateFormat('MMM d, HH:mm').format(
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
