import 'dart:async';
import 'package:flutter/material.dart';
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
import 'attendance_screen.dart';
import '../widgets/location_status_widget.dart';
import 'messages_screen.dart';
import 'employee_tasks_screen.dart';
import 'profile_screen.dart';
import 'notice_board_screen.dart';

class WebEmployeeView extends StatefulWidget {
  final User user;
  final int initialIndex;
  const WebEmployeeView({super.key, required this.user, this.initialIndex = 0});

  @override
  State<WebEmployeeView> createState() => _WebEmployeeViewState();
}

class _WebEmployeeViewState extends State<WebEmployeeView> {
  final SupabaseService _supabaseService = SupabaseService();

  late int _currentIndex;
  int _unreadCount = 0;
  Timer? _refreshTimer;
  Timer? _unreadCheckTimer;
  List<AttendanceRecord> _records = [];
  AttendanceType? _loadingType;

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
      } else if (mounted && _currentIndex == 3) {
        // Messages is at index 3 now
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
        });
      }
    } catch (e) {
      debugPrint('Error loading employee data: $e');
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
      NoticeBoardScreen(user: widget.user),
      MessagesScreen(user: widget.user),
      EmployeeTasksScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    return screens[_currentIndex.clamp(0, screens.length - 1)];
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
          _buildHistoryCard(),
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
    return Column(
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 2.0,
          children: [
            _buildActionButton(
              'CLOCK IN',
              Icons.login_rounded,
              AppColors.brand,
              () => _handleAttendance(AttendanceType.CLOCK_IN),
              _loadingType == AttendanceType.CLOCK_IN,
            ),
            _buildActionButton(
              'TAKE BREAK',
              Icons.coffee_rounded,
              Colors.orange,
              () => _handleAttendance(AttendanceType.BREAK_START),
              _loadingType == AttendanceType.BREAK_START,
            ),
            _buildActionButton(
              'GO TO OFFICE',
              Icons.business_rounded,
              Colors.blue,
              () => _handleAttendance(AttendanceType.CLOCK_IN),
              false,
            ),
            _buildActionButton(
              'CLOCK OUT',
              Icons.logout_rounded,
              Colors.redAccent,
              () => _handleAttendance(AttendanceType.CLOCK_OUT),
              _loadingType == AttendanceType.CLOCK_OUT,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color,
      VoidCallback onTap, bool isLoading) {
    return NeoCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const CircularProgressIndicator(
                    color: AppColors.brand, strokeWidth: 3)
              else ...[
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return NeoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'MY RECENT LOGS',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          Expanded(
            child: _records.isEmpty
                ? const Center(
                    child: Text('NO RECENT ACTIVITY',
                        style: TextStyle(color: Colors.white24, fontSize: 11)))
                : ListView.separated(
                    itemCount: _records.take(15).length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFF1A1A1A), height: 1),
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        title: Text(
                            record.type
                                .toString()
                                .split('.')
                                .last
                                .replaceAll('_', ' '),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          DateFormat('MMM d, HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                record.timestamp),
                          ),
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 10),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: Colors.white10, size: 16),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
