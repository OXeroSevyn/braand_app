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
          // Cyber Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                color: AppColors.brand.withOpacity(0.05),
                spacing: 40,
              ),
            ),
          ),

          // Main Layout
          Row(
            children: [
              // FIXED SIDEBAR (Brutalist Grid Design)
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: const Border(
                    right: BorderSide(color: AppColors.brand, width: 2),
                  ),
                ),
                child: Column(
                  children: [
                    // Top Branding
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.brand, width: 2),
                        ),
                      ),
                      child: Text(
                        'BRAANDINS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brand,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    // Navigation List
                    Expanded(
                      child: ListView(
                        children: [
                          _buildNavItem(
                              0, 'DASHBOARD', Icons.grid_view_rounded),
                          _buildNavItem(1, 'ATTENDANCE', Icons.timer_outlined),
                          _buildNavItem(2, 'NOTICES', Icons.campaign_outlined),
                          _buildNavItem(3, 'MESSAGES', Icons.message_outlined),
                          if (user.role == 'Admin') ...[
                            _buildNavItem(4, 'STAFF', Icons.people_outline),
                            _buildNavItem(
                                5, 'ANALYTICS', Icons.analytics_outlined),
                            _buildNavItem(
                                6, 'SETTINGS', Icons.settings_outlined),
                          ],
                        ],
                      ),
                    ),

                    // User Profile Grid Block
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.brand, width: 2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.brand),
                                ),
                                child: Center(
                                  child: Text(
                                    user.name[0],
                                    style: GoogleFonts.spaceMono(
                                        color: AppColors.brand,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name.toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      user.role.toUpperCase(),
                                      style: GoogleFonts.spaceMono(
                                        color: AppColors.brand,
                                        fontSize: 10,
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
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: Center(
                                child: Text(
                                  'TERMINATE SESSION',
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

              // MAIN CONTENT CONTAINER
              Expanded(
                child: Column(
                  children: [
                    // Action Bar / Breadcrumbs
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        border: Border(
                          bottom: BorderSide(color: AppColors.brand, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getNavTitle(_currentNavIndex),
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('EEE, MMM d, yyyy')
                                    .format(DateTime.now())
                                    .toUpperCase(),
                                style: GoogleFonts.spaceMono(
                                  color: AppColors.brand,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Consumer<ThemeProvider>(
                                builder: (context, theme, _) => IconButton(
                                  icon: Icon(
                                    theme.isDarkMode
                                        ? Icons.light_mode
                                        : Icons.dark_mode,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: theme.toggleTheme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // View Content
                    Expanded(
                      child: _buildBody(user),
                    ),
                  ],
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
    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? AppColors.brand : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.brand, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.normal,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                color: Colors.black,
              ),
            ],
          ],
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
