import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_setting.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local notifications plugin for foreground display
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permissions
    await requestPermissions();

    // 2. Initialize Local Notifications (for displaying foreground messages)
    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Note: iOS settings setup omitted for brevity but can be added if needed
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(initializationSettings);
    }

    // 3. Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');

        if (!kIsWeb) {
          _showForegroundNotification(message);
        }
      }
    });

    // 5. Get and print token (for testing)
    final token = await getToken();
    debugPrint('Firebase Messaging Token: $token');

    // Save token if user is already logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null && token != null) {
      await saveTokenToDatabase(currentUser.id, token);
    }

    // Listen for token updates
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        saveTokenToDatabase(user.id, newToken);
      }
    });

    _isInitialized = true;
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return await _firebaseMessaging.getToken(
        vapidKey:
            "BDzoXdezo3CF1M4mq5gOLb9McnSdkZtO7PZeXHxX4Ldy99hRG4oOW7C08ent7UYF5nTK5nLc5tT8AfOQ4D6bgGw",
      );
    }
    return await _firebaseMessaging.getToken();
  }

  Future<void> saveTokenToDatabase(String userId, String token) async {
    try {
      debugPrint('💾 Saving FCM token for user $userId');
      // Use the newly added method in SupabaseService
      // We can access it via a singleton or new instance since it's stateless wrapper
      // But simpler is to direct call via Supabase client if we didn't want to couple to the service class
      // However, we added updateFcmToken to SupabaseService, so let's use it.

      // Since NotificationService is a singleton and SupabaseService is usually instantiated,
      // we can just instantiate it here or make it static.
      // For now, let's just do a direct DB call to avoid circular deps or service instantiation issues if any.

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);

      debugPrint('✅ FCM token saved to Supabase');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  Future<bool> requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // channel Id
            'High Importance Notifications', // channel Name
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  // --- Methods to keep API compatibility with replaced stub ---
  // Many of these were for local scheduled notifications.
  // We will leave them as empty/stubs or partial implementations if they drift from FCM scope.

  Future<void> scheduleNotificationsFromSettings(
      List<NotificationSetting> settings) async {
    // TODO: Implement local scheduling if needed, or rely on backend scheduling via FCM
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<bool> canScheduleExactAlarms() async => true; // Valid for FCM usage

  Future<bool> requestExactAlarmPermission() async => true;

  Future<void> sendImmediateNotification(
      {required String title, required String message, int? id}) async {
    await _localNotifications.show(
      id ?? 0,
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showTestNotification() async {
    await sendImmediateNotification(
        title: "Test", message: "This is a test notification");
  }

  Future<void> loadAndScheduleNotifications() async {}

  void listenForCustomNotifications(String userId) {
    // This might be replaced by topic subscription in FCM
    _firebaseMessaging.subscribeToTopic('user_$userId');
    _firebaseMessaging.subscribeToTopic('all_users');
  }

  void listenForTableNotifications(String userId) {
    Supabase.instance.client
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            showLocalNotification(
              title: newRecord['title'] ?? 'New Notification',
              body: newRecord['body'] ?? '',
              payload: newRecord['data']?.toString(),
            );
          },
        )
        .subscribe();
  }

  Future<void> showLocalNotification(
      {required String title, required String body, String? payload}) async {
    const androidDetails = AndroidNotificationDetails(
      'braand_channel',
      'Task Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}
