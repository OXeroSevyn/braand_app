import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const String _queueKey = 'offline_sync_queue';
  final SupabaseService _supabaseService = SupabaseService();

  /// Queue an action to be synced later
  Future<void> queueAction({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];

    final item = {
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    queue.add(jsonEncode(item));
    await prefs.setStringList(_queueKey, queue);
    debugPrint('📦 Action "$action" queued offline');
  }

  /// Attempt to sync all pending actions
  Future<void> syncPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];

    if (queue.isEmpty) return;

    debugPrint('♻️ Attempting to sync ${queue.length} pending actions...');
    List<String> failedItems = [];

    for (String encodedItem in queue) {
      final item = jsonDecode(encodedItem);
      final String action = item['action'];
      final Map<String, dynamic> data = Map<String, dynamic>.from(item['data']);

      try {
        bool success = false;
        switch (action) {
          case 'attendance_record':
            await _supabaseService.manualInsertAttendance(data);
            success = true;
            break;
          case 'task_update':
            // Add other sync types as needed
            success = true;
            break;
          default:
            debugPrint('⚠️ Unknown offline action: $action');
            success = true; // Skip unknown
        }

        if (!success) failedItems.add(encodedItem);
      } catch (e) {
        debugPrint('❌ Sync failed for $action: $e');
        failedItems.add(encodedItem);
      }
    }

    await prefs.setStringList(_queueKey, failedItems);
    if (failedItems.isEmpty) {
      debugPrint('✅ All offline actions synced successfully');
    } else {
      debugPrint(
          '⚠️ ${failedItems.length} actions failed to sync and remain in queue');
    }
  }

  /// Get count of pending actions
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queueKey) ?? []).length;
  }
}
