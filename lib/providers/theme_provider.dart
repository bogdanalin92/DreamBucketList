import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final String _darkModeKey = 'isDarkMode';

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
          primaryColor: Colors.teal,
          colorScheme: const ColorScheme.dark().copyWith(
            primary: Colors.teal,
            secondary: Colors.tealAccent,
          ),
        )
        : ThemeData.light().copyWith(
          primaryColor: Colors.teal,
          colorScheme: const ColorScheme.light().copyWith(
            primary: Colors.teal,
            secondary: Colors.tealAccent,
          ),
        );
  }
}
