import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'web_admin_view.dart';
import 'web_employee_view.dart';
import 'attendance_screen.dart';
import 'messages_screen.dart';
import 'notice_board_screen.dart';
import 'user_management_screen.dart';
import 'admin_employee_list_screen.dart';
import 'reports_screen.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Subtle Cyber Grid
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                color: AppColors.brand.withOpacity(0.03),
                spacing: 60,
              ),
            ),
          ),

          // Main Layout
          Row(
            children: [
              // CLEAN SIDEBAR
              Container(
                width: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  border: Border(
                    right: BorderSide(color: Color(0xFF1A1A1A), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Branding
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'BRAANDINS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Navigation
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView(
                          children: [
                            _buildNavItem(
                                0, 'Dashboard', Icons.dashboard_rounded),
                            _buildNavItem(1, 'Attendance', Icons.timer_rounded),
                            _buildNavItem(2, 'Notices', Icons.campaign_rounded),
                            _buildNavItem(3, 'Messages', Icons.message_rounded),
                            if (user.role == 'Admin') ...[
                              const Padding(
                                padding: EdgeInsets.only(
                                    top: 24, bottom: 12, left: 16),
                                child: Text(
                                  'MANAGEMENT',
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              _buildNavItem(
                                  4, 'Employees', Icons.people_rounded),
                              _buildNavItem(
                                  5, 'Reports', Icons.analytics_rounded),
                              _buildNavItem(
                                  6, 'Settings', Icons.settings_rounded),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // User Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.brand,
                                child: Text(
                                  user.name[0],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      user.role.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => auth.logout(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'LOGOUT',
                                  style: GoogleFonts.spaceMono(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // MAIN CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getNavTitle(_currentNavIndex).toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d')
                                    .format(DateTime.now()),
                                style: GoogleFonts.spaceMono(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Consumer<ThemeProvider>(
                                builder: (context, theme, _) => InkWell(
                                  onTap: theme.toggleTheme,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      theme.isDarkMode
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Canvas
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: const Color(0xFF1A1A1A), width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildBody(user),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    bool isActive = _currentNavIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => setState(() => _currentNavIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: isActive ? Colors.black : Colors.white60,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNavTitle(int index) {
    switch (index) {
      case 0:
        return 'DASHBOARD_LIVE';
      case 1:
        return 'ATTENDANCE_LOGS';
      case 2:
        return 'SYSTEM_NOTICES';
      case 3:
        return 'ENCRYPTED_MESSAGES';
      case 4:
        return 'STAFF_DIRECTORY';
      case 5:
        return 'ANALYTICS_REPORT';
      case 6:
        return 'SYSTEM_CONFIG';
      default:
        return 'TERMINAL';
    }
  }

  Widget _buildBody(User user) {
    // Current mapping:
    // 0: Dashboard (WebAdminView or WebEmployeeView internal dashboard)
    // 1: Attendance
    // 2: Notices
    // 3: Messages
    // 4: Staff (Admin Only)
    // 5: Analytics (Admin Only)
    // 6: Settings (Admin Only)

    switch (_currentNavIndex) {
      case 0:
        return user.role == 'Admin'
            ? const WebAdminView(initialIndex: 0)
            : WebEmployeeView(user: user, initialIndex: 0);
      case 1:
        return AttendanceScreen(user: user, isAdminView: user.role == 'Admin');
      case 2:
        return NoticeBoardScreen(user: user);
      case 3:
        return MessagesScreen(user: user, isAdminView: user.role == 'Admin');
      case 4:
        return const AdminEmployeeListScreen();
      case 5:
        return const ReportsScreen();
      case 6:
        return const UserManagementScreen(); // Using as general settings/config for now
      default:
        return const Center(child: Text('404 :: SECTION_NOT_FOUND'));
    }
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
