import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/continuous_banner.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';
import '../services/supabase_service.dart';
import '../services/attendance_verification_service.dart';
import '../services/office_hours_service.dart';
import '../services/offline_sync_service.dart';
import '../widgets/clock_widget.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../widgets/location_status_widget.dart';
import '../widgets/mood_slider.dart';
import '../widgets/streak_card.dart';
import '../widgets/daily_focus.dart';
import '../widgets/broadcast_stories.dart';
import 'attendance_screen.dart';
import 'employee_tasks_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'notice_board_screen.dart';
import 'leave_screen.dart';
import 'leaderboard_screen.dart';
import '../services/notification_service.dart';

class EmployeeView extends StatefulWidget {
  final User user;
  const EmployeeView({super.key, required this.user});

  @override
  State<EmployeeView> createState() => _EmployeeViewState();
}

class _EmployeeViewState extends State<EmployeeView> {
  final SupabaseService _supabaseService = SupabaseService();
  final AttendanceVerificationService _verificationService =
      AttendanceVerificationService();
  final OfficeHoursService _officeHoursService = OfficeHoursService();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _refreshTimer;
  Timer? _unreadCheckTimer;
  List<AttendanceRecord> _records = [];
  int _streak = 0;
  List<String> _topTasks = [];
  String _latestNotice = '';
  List<Map<String, String>> _notices = [];
  String? _selectedMood;
  String _status = 'IDLE';
  AttendanceType? _loadingType; // Track which button is loading
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
    _startUnreadCheck();

    // Initialize Notifications
    NotificationService().initialize();
    NotificationService().listenForTableNotifications(widget.user.id);
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
      if (mounted && _currentIndex != 3) {
        // Only check when not on Messages tab (index 3 now)
        try {
          HapticFeedback.mediumImpact();
          final count = await _supabaseService.getUnreadCount(widget.user.id);
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
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
      final records = await _supabaseService.getUserRecords(widget.user.id);
      final streak = await _supabaseService.calculateStreak(widget.user.id);

      // Fetch Daily Focus data
      final dailyTasks = await _supabaseService.getDailyTasks(
        date: DateTime.now(),
        userId: widget.user.id,
      );
      final notices = await _supabaseService.getNotices();

      if (mounted) {
        setState(() {
          _records = records;
          _streak = streak;
          _topTasks =
              dailyTasks.take(2).map((t) => t['title'] as String).toList();
          if (notices.isNotEmpty) {
            _latestNotice = notices.first.title;
          }
          _notices = notices
              .map((n) => {
                    'title': n.title,
                    'category': n.priority == 'HIGH' ? 'URGENT' : 'NEWS',
                  })
              .toList();
          _determineStatus(records);
        });
      }

      // Check for offline items and sync
      final pendingCount = await _offlineSyncService.getPendingCount();
      if (mounted) setState(() => _pendingSyncCount = pendingCount);

      if (pendingCount > 0 && !_isSyncing) {
        _syncOfflineData();
      }
    } catch (e) {
      debugPrint('Error loading employee data: $e');
    }
  }

  Future<void> _syncOfflineData() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await _offlineSyncService.syncPendingActions();
      final count = await _offlineSyncService.getPendingCount();
      if (mounted) {
        setState(() {
          _pendingSyncCount = count;
          _isSyncing = false;
        });
        if (count == 0) {
          _loadData(); // Reload to get newly synced records
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSyncing = false);
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
      // Step 0: Check office hours (BLOCKING)
      final officeHoursStatus = await _officeHoursService.checkOfficeHours();

      if (!officeHoursStatus.isWithinHours) {
        if (mounted) {
          _showErrorDialog(
            officeHoursStatus.message ?? 'Outside office hours',
          );
        }
        return;
      }

      // Step 1: Check if device is registered
      final isRegistered =
          await _verificationService.isCurrentDeviceRegistered(widget.user.id);

      if (!isRegistered) {
        if (mounted) {
          final shouldRegister = await _showDeviceRegistrationDialog();
          if (shouldRegister == true) {
            final registered = await _verificationService
                .registerCurrentDevice(widget.user.id);
            if (!registered) {
              _showErrorDialog('Failed to register device. Please try again.');
              return;
            }
            _showSuccessDialog('Device registered successfully!');
          } else {
            return; // User cancelled
          }
        }
      }

      // Step 2: Perform verification
      final verificationResult = await _verificationService.verifyAttendance(
        userId: widget.user.id,
        type: type,
        requirePhoto: false, // Can be made configurable
      );

      if (!verificationResult.success) {
        if (mounted) {
          _showErrorDialog(
              verificationResult.errorMessage ?? 'Verification failed');
        }
        return;
      }

      // Step 3: Verify location (handled inside service)

      // Step 4: Save attendance record with verification data
      // Show Mood Slider if it's a CLOCK_IN
      if (type == AttendanceType.CLOCK_IN && mounted) {
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: MoodSlider(
              onMoodSelected: (mood) {
                setState(() => _selectedMood = mood);
              },
            ),
          ),
        );
      }

      // Get accurate location for the record
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('⚠️ Error getting position for record: $e');
      }

      final record = AttendanceRecord(
        id: '',
        userId: widget.user.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: type,
        location: position != null
            ? Location(lat: position.latitude, lng: position.longitude)
            : null,
        deviceId: verificationResult.deviceId,
        biometricVerified: verificationResult.biometricVerified,
        photoUrl: verificationResult.photoUrl,
        verificationMethod: verificationResult.verificationMethod,
        mood: _selectedMood,
      );

      await _supabaseService.saveRecord(record);
      await _loadData();

      if (mounted) {
        _showSuccessDialog(
            '${type.toString().split('.').last.replaceAll('_', ' ')} recorded successfully!');
      }
    } catch (e) {
      debugPrint('Error saving record: $e');
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingType = null);
      }
    }
  }

  Future<bool?> _showDeviceRegistrationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Register Device',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This device is not registered. Would you like to register it now for secure attendance tracking?',
          style: GoogleFonts.spaceMono(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.spaceMono()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
            child: Text('REGISTER',
                style: GoogleFonts.spaceMono(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Verification Failed',
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(message, style: GoogleFonts.spaceMono(fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.spaceMono()),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceMono()),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          AttendanceScreen(user: widget.user),
          EmployeeTasksScreen(user: widget.user),
          MessagesScreen(user: widget.user),
          _buildMenuScreen(), // New menu screen
        ],
      ),
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
              label: 'HOME',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'ATTENDANCE',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              label: 'TASKS',
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'MENU',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.brand, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MENU',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Additional features and settings',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NeoCard(
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.account_circle,
                  title: 'Profile',
                  subtitle: 'View and edit your profile',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.leaderboard,
                  title: 'Ranking',
                  subtitle: 'View leaderboard rankings',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.flight_takeoff,
                  title: 'Leave Requests',
                  subtitle: 'Submit and manage leaves',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.assignment,
                  title: 'Notice Board',
                  subtitle: 'View announcements',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NoticeBoardScreen(user: widget.user),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey[100],
                  border: Border.all(
                    color: isDark ? Colors.white : Colors.black,
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContinuousBanner(isDark: isDark),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ClockWidget(),
                if (_pendingSyncCount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _isSyncing
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      border: Border.all(
                        color: _isSyncing ? Colors.blue : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: _isSyncing
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                )
                              : const Icon(Icons.cloud_off,
                                  size: 16, color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isSyncing
                                ? 'Syncing $_pendingSyncCount records...'
                                : 'Offline: $_pendingSyncCount records ready to sync',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isSyncing ? Colors.blue : Colors.orange,
                            ),
                          ),
                        ),
                        if (!_isSyncing)
                          GestureDetector(
                            onTap: _syncOfflineData,
                            child: const Icon(Icons.sync,
                                size: 20, color: Colors.orange),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                LocationStatusWidget(),
                const SizedBox(height: 24),

                // Actions
                _buildActions(),
                const SizedBox(height: 24),

                // Broadcast Stories
                BroadcastStories(
                  notices: _notices,
                  onStoryTap: (notice) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NoticeBoardScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Streak & Daily Focus
                Row(
                  children: [
                    Expanded(child: StreakCard(streak: _streak)),
                  ],
                ),
                const SizedBox(height: 16),
                DailyFocus(
                  topTasks: _topTasks,
                  latestNotice: _latestNotice,
                ),
                const SizedBox(height: 24),

                // Charts & AI
                _buildChartsAndAI(),
                const SizedBox(height: 24),

                // Logs
                _buildLogs(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, size: 20),
              const SizedBox(width: 8),
              Text(
                'ACTIONS',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeoButton(
                  text: 'CLOCK IN',
                  color: AppColors.brand, // Lime green
                  textColor: Colors.black,
                  onPressed: _status == 'IDLE' || _status == 'COMPLETED'
                      ? () => _handleAttendance(AttendanceType.CLOCK_IN)
                      : null,
                  isLoading: _loadingType == AttendanceType.CLOCK_IN,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoButton(
                  text: 'CLOCK OUT',
                  color: Colors.red,
                  textColor: Colors.white,
                  onPressed: _status == 'ACTIVE' || _status == 'ON_BREAK'
                      ? () => _handleAttendance(AttendanceType.CLOCK_OUT)
                      : null,
                  isLoading: _loadingType == AttendanceType.CLOCK_OUT,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: NeoButton(
                  text: 'BREAK START',
                  color: Colors.purple,
                  textColor: Colors.white,
                  onPressed: _status == 'ACTIVE'
                      ? () => _handleAttendance(AttendanceType.BREAK_START)
                      : null,
                  isLoading: _loadingType == AttendanceType.BREAK_START,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoButton(
                  text: 'BREAK END',
                  color: Colors.amber,
                  textColor: Colors.black,
                  onPressed: _status == 'ON_BREAK'
                      ? () => _handleAttendance(AttendanceType.BREAK_END)
                      : null,
                  isLoading: _loadingType == AttendanceType.BREAK_END,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsAndAI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 20),
              const SizedBox(width: 8),
              Text(
                'INSIGHTS',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: _buildWeeklyChart(isDark)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(bool isDark) {
    // Calculate hours for last 7 days
    final now = DateTime.now();
    final List<double> dailyHours = [];
    final List<String> labels = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayRecords = _records.where((r) {
        final recordDate = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        return recordDate.year == date.year &&
            recordDate.month == date.month &&
            recordDate.day == date.day;
      }).toList();

      // Sort by timestamp to ensure correct order
      dayRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      double hours = 0;

      // Better calculation logic: find IN and subsequent OUT
      for (int j = 0; j < dayRecords.length; j++) {
        final record = dayRecords[j];
        if (record.type == AttendanceType.CLOCK_IN) {
          // Look for next CLOCK_OUT
          for (int k = j + 1; k < dayRecords.length; k++) {
            if (dayRecords[k].type == AttendanceType.CLOCK_OUT) {
              hours += (dayRecords[k].timestamp - record.timestamp) /
                  (1000 * 60 * 60);
              j = k; // Skip to this OUT record
              break;
            }
          }
        }
      }

      dailyHours.add(hours);
      labels.add(DateFormat('E').format(date));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 12,
        minY: 0, // Force start at 0
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? Colors.white : Colors.black,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)}h',
                GoogleFonts.spaceMono(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[value.toInt()],
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value < 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}h',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dailyHours.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dailyHours[index],
                color: AppColors.brand,
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 12,
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLogs() {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 8),
              Text(
                'RECENT LOGS',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_records.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No activity yet',
                  style: GoogleFonts.spaceMono(color: Colors.grey),
                ),
              ),
            )
          else
            ...(_records.take(5).map((record) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            _getTypeColor(record.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12), // Rounded
                        // Removed hard border
                      ),
                      child: Icon(
                        _getTypeIcon(record.type),
                        size: 20,
                        color: _getTypeColor(record.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTypeText(record.type),
                            style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy • HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  record.timestamp),
                            ),
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
        ],
      ),
    );
  }

  IconData _getTypeIcon(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return Icons.login;
      case AttendanceType.CLOCK_OUT:
        return Icons.logout;
      case AttendanceType.BREAK_START:
        return Icons.coffee;
      case AttendanceType.BREAK_END:
        return Icons.work;
    }
  }

  Color _getTypeColor(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return AppColors.brand;
      case AttendanceType.CLOCK_OUT:
        return Colors.red;
      case AttendanceType.BREAK_START:
        return Colors.purple;
      case AttendanceType.BREAK_END:
        return Colors.amber;
    }
  }

  String _getTypeText(AttendanceType type) {
    switch (type) {
      case AttendanceType.CLOCK_IN:
        return 'CLOCKED IN';
      case AttendanceType.CLOCK_OUT:
        return 'CLOCKED OUT';
      case AttendanceType.BREAK_START:
        return 'BREAK STARTED';
      case AttendanceType.BREAK_END:
        return 'BREAK ENDED';
    }
  }
}
