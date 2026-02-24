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

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background Gradient (Deep & Subtle)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F1A), // Deep Blue/Black
                    Color(0xFF050508), // Almost Black
                  ],
                ),
              ),
            ),
          ),

          // Accent Glows (Top Left)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.15),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Accent Glows (Bottom Right)
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandSecondary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandSecondary.withOpacity(0.1),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Content
          Row(
            children: [
              // Side Navigation (Glassmorphic)
              Container(
                width: 280,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16), // Floating look
                decoration: BoxDecoration(
                  color: AppColors.darkSurface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branding
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                          children: const [
                            TextSpan(text: 'BRAANDINS'),
                            TextSpan(
                                text: '.',
                                style:
                                    TextStyle(color: AppColors.brandSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // User Profile (Glass Card)
                    NeoCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3), // Border width
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.brandGradient,
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.darkSurface,
                              child: Text(
                                user.name[0],
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${user.role} • ${user.department}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Navigation Items
                    _buildNavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'DASHBOARD',
                      isActive: true,
                    ),
                    _buildNavItem(
                      icon: Icons.people_outline,
                      label: 'TEAM',
                      isActive: false,
                    ),
                    _buildNavItem(
                      icon: Icons.analytics_outlined,
                      label: 'REPORTS',
                      isActive: false,
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
                        onTap: theme.toggleTheme,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Logout
                    _buildNavItem(
                      icon: Icons.logout,
                      label: 'LOGOUT',
                      isActive: false,
                      isLogout: true,
                      onTap: () =>
                          Provider.of<AuthProvider>(context, listen: false)
                              .logout(),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 16, bottom: 16, right: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: user.role == 'Admin'
                        ? const WebAdminView()
                        : WebEmployeeView(user: user),
                  ),
                ),
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
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isActive ? AppColors.brandGradient : null,
              color: isActive ? null : Colors.transparent,
              border: isActive
                  ? null
                  : Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? Colors.white
                      : (isLogout ? Colors.redAccent : Colors.white60),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.white
                        : (isLogout ? Colors.redAccent : Colors.white60),
                    fontSize: 12,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
