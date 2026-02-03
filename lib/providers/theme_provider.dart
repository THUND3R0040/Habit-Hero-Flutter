import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  //ThemeNotifier() : super(AppThemeMode.system);
  static const _themeKey = 'app_theme';

  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static AppThemeMode _loadTheme(SharedPreferences prefs) {
    final stored = prefs.getString(_themeKey);
    if (stored == null) return AppThemeMode.system;

    return AppThemeMode.values.byName(stored);
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
    _prefs.setString(_themeKey, mode.name);
  }

  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier(ref.watch(sharedPreferencesProvider));
});
