import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;
  final StorageService _storageService = StorageService();

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _isDarkMode = await _storageService.getTheme();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.saveTheme(_isDarkMode);
    notifyListeners();
  }
}
