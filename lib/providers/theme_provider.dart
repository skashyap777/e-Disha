import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme state and persistence.
///
/// Use Provider.of<ThemeProvider>(context, listen: false).setThemeMode
/// to change theme from anywhere in your app.
class ThemeProvider with ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system; // Default to system

  ThemeProvider() {
    _loadThemeMode();
  }

  /// Current display theme
  ThemeMode get themeMode => _themeMode;

  /// Whether app is currently in dark mode
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeModeKey) ?? _themeMode.index;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      // Do nothing or log
    }
  }

  /// Sets and persists the app theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (e) {
      // Do nothing or log
    }
    notifyListeners();
  }

  /// Toggles between light and dark mode.
  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
