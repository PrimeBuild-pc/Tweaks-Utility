import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  // Dark theme colors
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCardBackground = Color(0xFF252525);
  static const darkAccent = Color(0xFFFF5722); // Orange accent
  static const darkSecondary = Color(0xFF424242); // Dark gray

  // Light theme colors - softer, less bright
  static const lightBackground = Color(0xFFE8EAF6); // Light indigo background
  static const lightSurface = Color(0xFFC5CAE9); // Lighter indigo surface
  static const lightCardBackground =
      Color(0xFFD1D9FF); // Very light indigo card
  static const lightAccent = Color(0xFF5C6BC0); // Indigo accent
  static const lightSecondary = Color(0xFF9FA8DA); // Light indigo secondary

  // Gradients
  static const orangeGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const indigoGradient = LinearGradient(
    colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isDarkMode = true;

  ThemeProvider(this._prefs) {
    _isDarkMode = _prefs.getBool('isDarkMode') ?? true;
  }

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
