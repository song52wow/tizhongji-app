import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

class SettingsService {
  static const String _settingsKey = 'user_settings';

  Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr != null) {
      return UserSettings.fromJson(json.decode(jsonStr));
    }
    return _defaultSettings();
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
  }

  UserSettings _defaultSettings() {
    final now = DateTime.now().toIso8601String();
    return UserSettings(
      id: 'default_user',
      unit: 'kg',
      morningReminderEnabled: false,
      eveningReminderEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}