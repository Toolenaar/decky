import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedManaColor = 'Plains';
  
  ThemeMode get themeMode => _themeMode;
  String get selectedManaColor => _selectedManaColor;
  
  Color get accentColor => AppTheme.manaColors[_selectedManaColor] ?? AppTheme.plainsGold;
  
  ThemeData get lightTheme => AppTheme.lightTheme(accentColor: accentColor);
  ThemeData get darkTheme => AppTheme.darkTheme(accentColor: accentColor);

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedThemeMode = prefs.getString(_themeModeKey);
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedThemeMode,
        orElse: () => ThemeMode.system,
      );
    }
    
    _selectedManaColor = prefs.getString(_accentColorKey) ?? 'Plains';
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> setManaColor(String manaColorName) async {
    if (AppTheme.manaColors.containsKey(manaColorName)) {
      _selectedManaColor = manaColorName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accentColorKey, manaColorName);
      notifyListeners();
    }
  }
}