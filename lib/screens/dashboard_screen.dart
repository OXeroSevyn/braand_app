import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/user_avatar.dart';
import 'admin_view.dart';
import 'employee_view.dart';
import 'web_dashboard_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return const WebDashboardScreen();
          }
          return _buildMobileLayout(context);
        },
      );
    }

    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            color: isDark ? Colors.white10 : Colors.black,
            height: 2,
          ),
        ),
        title: Row(
          children: [
            UserAvatar(
              avatarUrl: user.avatar,
              name: user.name,
              size: 40,
              showBorder: true,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${user.role} // ${user.department}'.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: isDark ? AppColors.brand : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, theme, _) => IconButton(
              onPressed: theme.toggleTheme,
              icon: Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            onPressed: () =>
                Provider.of<AuthProvider>(context, listen: false).logout(),
            icon: const Icon(Icons.logout),
            color: isDark ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user.role == 'Admin' ? const AdminView() : EmployeeView(user: user),
    );
  }
}
