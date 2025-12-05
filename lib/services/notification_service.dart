import '../models/notification_setting.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {}
  Future<bool> requestPermissions() async => true;
  Future<void> scheduleNotificationsFromSettings(
      List<NotificationSetting> settings) async {}
  Future<void> cancelAllNotifications() async {}
  Future<void> cancelNotification(int id) async {}
  Future<bool> canScheduleExactAlarms() async => true;
  Future<bool> requestExactAlarmPermission() async => true;
  Future<void> sendImmediateNotification(
      {required String title, required String message, int? id}) async {}
  Future<void> showTestNotification() async {}
  Future<void> loadAndScheduleNotifications() async {}
  void listenForCustomNotifications(String userId) {}
}
