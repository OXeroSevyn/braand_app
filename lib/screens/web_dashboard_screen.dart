import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'web_admin_view.dart';
import 'web_employee_view.dart';
import '../widgets/neo_card.dart';

class WebDashboardScreen extends StatelessWidget {
  const WebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
          ),

          // Content
          Row(
            children: [
              // Side Navigation
              Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branding
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        children: const [
                          TextSpan(text: 'BRAANDINS'),
                          TextSpan(
                              text: '.',
                              style: TextStyle(color: AppColors.brand)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // User Profile
                    NeoCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.brand,
                            child: Text(
                              user.name[0],
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${user.role} • ${user.department}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Navigation Items
                    _buildNavItem(
                      icon: Icons.dashboard,
                      label: 'DASHBOARD',
                      isActive: true,
                      isDark: isDark,
                    ),

                    const Spacer(),

                    // Theme Toggle
                    Consumer<ThemeProvider>(
                      builder: (context, theme, _) => _buildNavItem(
                        icon: theme.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        label: theme.isDarkMode ? 'LIGHT MODE' : 'DARK MODE',
                        isActive: false,
                        isDark: isDark,
                        onTap: theme.toggleTheme,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Logout
                    _buildNavItem(
                      icon: Icons.logout,
                      label: 'LOGOUT',
                      isActive: false,
                      isDark: isDark,
                      onTap: () =>
                          Provider.of<AuthProvider>(context, listen: false)
                              .logout(),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: user.role == 'Admin'
                    ? const WebAdminView()
                    : WebEmployeeView(user: user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brand
              : (isDark ? Colors.transparent : Colors.transparent),
          border: Border.all(
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black : Colors.black,
                    offset: const Offset(4, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 40.0;

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
