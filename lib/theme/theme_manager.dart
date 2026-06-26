import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themes.dart';

class ThemeManager extends ChangeNotifier {
  static const _themeIndexKey = 'theme_index';
  static const _darkModeKey = 'dark_mode';

  int _selectedThemeIndex = 0;
  bool _isDarkMode = false;

  int get selectedThemeIndex => _selectedThemeIndex;
  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme {
    final theme = AppThemes.themes[_selectedThemeIndex];
    return _isDarkMode ? theme.dark : theme.light;
  }

  AppTheme get currentAppTheme => AppThemes.themes[_selectedThemeIndex];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedThemeIndex = prefs.getInt(_themeIndexKey) ?? 0;
    final darkVal = prefs.get(_darkModeKey);
    _isDarkMode = darkVal == true || darkVal == 'true';
    notifyListeners();
  }

  Future<void> setTheme(int index) async {
    if (index < 0 || index >= AppThemes.themes.length) return;
    _selectedThemeIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeIndexKey, index);
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_darkModeKey, _isDarkMode ? 'true' : 'false');
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_darkModeKey, value ? 'true' : 'false');
  }
}
