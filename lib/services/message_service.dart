import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Messages ---

  /// Send a message from sender to recipient
  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String message,
  }) async {
    await _supabase.from('messages').insert({
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message': message,
    });
  }

  /// Get conversation between two users (sorted by newest first)
  Future<List<Map<String, dynamic>>> getConversation(
    String userId1,
    String userId2,
  ) async {
    final response = await _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles!messages_sender_id_fkey(name),
          recipient:profiles!messages_recipient_id_fkey(name)
        ''')
        .or('and(sender_id.eq.$userId1,recipient_id.eq.$userId2),and(sender_id.eq.$userId2,recipient_id.eq.$userId1)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get all messages for a user (received messages)
  Future<List<Map<String, dynamic>>> getMessagesForUser(String userId) async {
    final response = await _supabase.from('messages').select('''
          *,
          sender:profiles!messages_sender_id_fkey(name, role),
          recipient:profiles!messages_recipient_id_fkey(name)
        ''').eq('recipient_id', userId).order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _supabase.from('messages').update({'read': true}).eq('id', messageId);
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from('messages')
        .select('id')
        .eq('recipient_id', userId)
        .eq('read', false)
        .count(CountOption.exact);

    return response.count;
  }

  /// Subscribe to new messages for real-time updates
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String userId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // --- Custom Notifications (Realtime) ---

  /// Send a custom notification to all employees
  Future<void> sendCustomNotification({
    required String title,
    required String message,
  }) async {
    await _supabase.from('custom_notifications').insert({
      'title': title,
      'message': message,
      'created_by': _supabase.auth.currentUser?.id,
    });
  }

  /// Subscribe to new custom notifications
  Stream<Map<String, dynamic>> subscribeToCustomNotifications() {
    final controller = StreamController<Map<String, dynamic>>();

    debugPrint('🔔 Subscribing to public:custom_notifications');
    _supabase
        .channel('public:custom_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'custom_notifications',
          callback: (payload) {
            debugPrint(
                '🔔 Notification Payload received: ${payload.newRecord}');
            controller.add(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
      debugPrint('🔔 Subscription status: $status ${error ?? ""}');
    });

    return controller.stream;
  }

  // --- Notifications ---

  /// Send a notification (Insert into DB)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Notification sent to $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  // --- Notification Settings ---

  /// Get all notification settings
  Future<List<Map<String, dynamic>>> getNotificationSettings() async {
    final response = await _supabase
        .from('notification_settings')
        .select()
        .order('type', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Update a notification setting
  Future<void> updateNotificationSetting({
    required String id,
    bool? enabled,
    String? time,
    String? message,
    List<String>? daysOfWeek,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (enabled != null) updates['enabled'] = enabled;
    if (time != null) updates['time'] = time;
    if (message != null) updates['message'] = message;
    if (daysOfWeek != null) updates['days_of_week'] = daysOfWeek;

    await _supabase.from('notification_settings').update(updates).eq('id', id);
  }

  /// Create a new notification setting
  Future<void> createNotificationSetting({
    required String type,
    required bool enabled,
    required String time,
    required String message,
    required List<String> daysOfWeek,
  }) async {
    await _supabase.from('notification_settings').insert({
      'type': type,
      'enabled': enabled,
      'time': time,
      'message': message,
      'days_of_week': daysOfWeek,
    });
  }

  /// Delete a notification setting
  Future<void> deleteNotificationSetting(String id) async {
    await _supabase.from('notification_settings').delete().eq('id', id);
  }

  // --- Banner Announcements ---

  Future<List<Map<String, dynamic>>> getBannerAnnouncements() async {
    try {
      final response = await _supabase
          .from('banner_announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching banner announcements: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamBannerAnnouncements() {
    return _supabase
        .from('banner_announcements')
        .stream(primaryKey: ['id']).map((data) {
      final List<Map<String, dynamic>> list =
          List<Map<String, dynamic>>.from(data);
      list.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
      return list.where((e) => e['is_active'] == true).toList();
    });
  }

  Future<void> createBannerAnnouncement({
    required String message,
    DateTime? expiresAt,
  }) async {
    await _supabase.from('banner_announcements').insert({
      'message': message,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'created_by': _supabase.auth.currentUser?.id,
    });
  }

  Future<void> deleteBannerAnnouncement(String id) async {
    await _supabase
        .from('banner_announcements')
        .update({'is_active': false}).eq('id', id);
  }
}
