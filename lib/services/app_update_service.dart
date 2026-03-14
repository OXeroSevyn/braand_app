import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version.dart';

class AppUpdateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AppVersion?> checkForUpdates() async {
    try {
      debugPrint('🔄 Checking for app updates...');

      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersionCode = int.parse(packageInfo.buildNumber);
      debugPrint('📱 Current Version Code: $currentVersionCode');

      // Get latest version from DB
      final response = await _supabase
          .from('app_versions')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('✅ No update information found in DB.');
        return null;
      }

      final latestVersion = AppVersion.fromJson(response);
      debugPrint('🚀 Latest Version Code: ${latestVersion.versionCode}');

      if (latestVersion.versionCode > currentVersionCode) {
        debugPrint('🌟 Update Available!');
        return latestVersion;
      } else {
        debugPrint('✅ App is up to date.');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }

  Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch user url');
    }
  }

  Future<void> publishAppVersion({
    required int versionCode,
    required String versionName,
    required String apkUrl,
    required String releaseNotes,
    required bool forceUpdate,
  }) async {
    try {
      await _supabase.from('app_versions').insert({
        'version_code': versionCode,
        'version_name': versionName,
        'apk_url': apkUrl,
        'release_notes': releaseNotes,
        'force_update': forceUpdate,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ App version published successfully!');
    } catch (e) {
      debugPrint('❌ Error publishing app version: $e');
      rethrow;
    }
  }
}
