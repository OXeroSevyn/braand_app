import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/web_auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'services/notification_service.dart';
import 'services/permissions_service.dart';
import 'widgets/global_notification_listener.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_credentials.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseCredentials.url,
    anonKey: SupabaseCredentials.anonKey,
  );

  // Skip mobile-only features on web
  if (!kIsWeb) {
    // Initialize notification service (mobile only)
    try {
      /*
      print('🔔 Initializing notification service...');
      final notificationService = NotificationService();
      await notificationService.initialize();

      print('📱 Requesting notification permissions...');
      final permissionGranted = await notificationService.requestPermissions();
      print('  Permission granted: $permissionGranted');

      // Check exact alarm permission (Android 12+)
      final canScheduleExact =
          await notificationService.canScheduleExactAlarms();
      print('  Can schedule exact alarms: $canScheduleExact');

      if (!canScheduleExact) {
        print(
            '⚠️  Warning: Exact alarm permission not granted. Notifications may not work properly.');
      }
      */

      // Note: Notifications are now scheduled in AuthProvider after successful login
      // to ensure we have proper database access permissions.
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    // Request all required permissions on first launch (mobile only)
    // We don't await this to ensure the app starts quickly.
    PermissionsService.requestAll().then((granted) {
      debugPrint('All permissions granted: $granted');
    });
  } else {
    debugPrint('🌐 Running on web - skipping mobile-only features');
  }

  // Proceed to run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, theme, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(false),
            darkTheme: _buildTheme(true),
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: auth.isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : GlobalNotificationListener(
                    child: auth.user != null
                        ? (auth.isPending
                            ? const PendingApprovalScreen()
                            : const DashboardScreen())
                        : (kIsWeb ? const WebAuthScreen() : const AuthScreen()),
                  ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(bool isDark) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.brand,
        secondary: AppColors.brand,
        surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: isDark ? Colors.white : Colors.black,
        displayColor: isDark ? Colors.white : Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: isDark ? Colors.white : Colors.black,
              width: 2,
            ),
          ),
          elevation: 0,
        ).copyWith(shadowColor: MaterialStateProperty.all(Colors.transparent)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.black : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: isDark ? AppColors.brand : Colors.black,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.spaceMono(
          color: isDark ? AppColors.brand : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
