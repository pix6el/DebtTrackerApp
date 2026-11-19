import 'package:flutter/material.dart';
import '../data/db_helper.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._internal() : super(ThemeMode.system);
  static final ThemeController instance = ThemeController._internal();

  static const String _themeSettingKey = 'theme_mode';

  Future<void> load() async {
    final saved = await DbHelper.instance.getSetting(_themeSettingKey);
    value = _fromString(saved);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    await DbHelper.instance.setSetting(_themeSettingKey, _toString(mode));
  }

  static ThemeMode _fromString(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
