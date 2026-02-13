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
import '../services/supabase_service.dart';
import '../models/app_version.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    final supabaseService = SupabaseService();
    final update = await supabaseService.checkForUpdates();

    if (update != null && mounted) {
      _showUpdateDialog(update);
    }
  }

  void _showUpdateDialog(AppVersion update) {
    showDialog(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => !update.forceUpdate,
          child: AlertDialog(
            title: const Text('Update Available 🚀'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new version ${update.versionName} is available.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (update.releaseNotes != null) ...[
                  const SizedBox(height: 10),
                  const Text('What\'s new:'),
                  Text(update.releaseNotes!),
                ],
                if (update.forceUpdate) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'This is a mandatory update. Please update to continue using the app.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              if (!update.forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
              ElevatedButton(
                onPressed: () {
                  SupabaseService().launchUpdateUrl(update.apkUrl);
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }

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
    final user = Provider.of<AuthProvider>(context).user;

    // Handle case where user might be null briefly during logout/auth state change
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2, // Modern material 3 style
        shadowColor: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            UserAvatar(
              avatarUrl: user.avatar,
              name: user.name,
              size: 40,
              showBorder: false, // Cleaner look
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
                  '${user.role} • ${user.department}', // Changed // to bullet
                  style: GoogleFonts.spaceGrotesk(
                    // Changed to Grotesk
                    fontSize: 11,
                    color: isDark ? AppColors.brand : Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
