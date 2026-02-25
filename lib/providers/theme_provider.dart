import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;
  bool _isSnowfallEnabled = !kIsWeb;
  final StorageService _storageService = StorageService();

  bool get isDarkMode => _isDarkMode;
  bool get isSnowfallEnabled => _isSnowfallEnabled;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _isDarkMode = await _storageService.getTheme();
    _isSnowfallEnabled = await _storageService.getSnowfall();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.saveTheme(_isDarkMode);
    notifyListeners();
  }

  void toggleSnowfall() {
    _isSnowfallEnabled = !_isSnowfallEnabled;
    _storageService.saveSnowfall(_isSnowfallEnabled);
    notifyListeners();
  }
}
