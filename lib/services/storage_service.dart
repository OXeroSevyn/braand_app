import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';

class StorageService {
  static const String KEY_USER = 'braandins_user';
  static const String KEY_THEME = 'braandins_theme';
  static const String KEY_RECORDS = 'braandins_records';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_USER, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(KEY_USER);
    if (userStr != null) {
      return User.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_USER);
  }

  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_THEME, isDark ? 'dark' : 'light');
  }

  Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(KEY_THEME);
    return theme ==
        'dark'; // Default to false (light) if null, or true if 'dark'
  }

  Future<void> saveRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.insert(0, record); // Add to beginning

    final List<String> recordsJson = records
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    await prefs.setStringList(KEY_RECORDS, recordsJson);
  }

  Future<List<AttendanceRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsList = prefs.getStringList(KEY_RECORDS);
    if (recordsList != null) {
      return recordsList
          .map((r) => AttendanceRecord.fromJson(jsonDecode(r)))
          .toList();
    }
    return [];
  }

  // Mock data for employees (since we don't have a real backend)
  List<User> getAllEmployees() {
    return [
      User(
        id: '1',
        name: 'John Doe',
        email: 'john@braandins.com',
        role: 'Employee',
        department: 'Engineering',
        avatar: null,
      ),
      User(
        id: '2',
        name: 'Jane Smith',
        email: 'jane@braandins.com',
        role: 'Employee',
        department: 'Design',
        avatar: null,
      ),
      User(
        id: '3',
        name: 'Mike Johnson',
        email: 'mike@braandins.com',
        role: 'Employee',
        department: 'Marketing',
        avatar: null,
      ),
    ];
  }
}
