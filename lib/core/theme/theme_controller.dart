import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

class ThemeController extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.light;
  SharedPreferences? _prefs;

  AppTheme get currentTheme => _currentTheme;

  ThemeData get themeData => AppThemes.getTheme(_currentTheme);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString('app_theme');

    if (savedTheme != null) {
      try {
        _currentTheme = AppTheme.values.byName(savedTheme);
      } catch (e) {
        _currentTheme = AppTheme.light;
      }
    }
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    await _prefs?.setString('app_theme', theme.name);
    notifyListeners();
  }

  // Backward compatibility with ThemeMode
  ThemeMode get mode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.green:
        return ThemeMode.dark;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    final theme = mode == ThemeMode.light ? AppTheme.light : AppTheme.dark;
    await setTheme(theme);
  }
}

final ThemeController themeController = ThemeController();
