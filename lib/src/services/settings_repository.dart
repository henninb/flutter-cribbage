import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_settings.dart';

/// Repository for managing game settings persistence
class SettingsRepository {
  static const String _settingsKey = 'game_settings';

  /// Load game settings from persistent storage
  Future<GameSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString == null) {
        return const GameSettings(); // Return default settings
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GameSettings.fromJson(json);
    } catch (e) {
      // If there's any error loading settings, return defaults
      return const GameSettings();
    }
  }

  /// Save game settings to persistent storage
  Future<void> saveSettings(GameSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, jsonString);
    } catch (e) {
      // Silently fail - settings just won't persist
    }
  }
}
