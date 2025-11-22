import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/engine/game_engine.dart';
import 'ui/screens/game_screen.dart';
import 'models/theme_models.dart';
import 'models/game_settings.dart';
import 'ui/theme/theme_calculator.dart';
import 'ui/theme/theme_definitions.dart';
import 'services/settings_repository.dart';

class CribbageApp extends StatefulWidget {
  const CribbageApp({super.key});

  @override
  State<CribbageApp> createState() => _CribbageAppState();
}

class _CribbageAppState extends State<CribbageApp> {
  late CribbageTheme _currentTheme;
  late GameSettings _currentSettings;
  final _settingsRepository = SettingsRepository();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load settings from persistent storage
    _currentSettings = await _settingsRepository.loadSettings();

    // Load theme based on settings or date
    _currentTheme = _getThemeFromSettings(_currentSettings);

    setState(() {
      _isInitialized = true;
    });
  }

  CribbageTheme _getThemeFromSettings(GameSettings settings) {
    if (settings.selectedTheme != null) {
      // Use selected theme from settings
      return ThemeDefinitions.getThemeByType(settings.selectedTheme!);
    } else {
      // Use date-based theme
      return ThemeCalculator.getCurrentTheme();
    }
  }

  void _handleThemeChange(CribbageTheme newTheme) {
    setState(() {
      _currentTheme = newTheme;
    });
  }

  void _handleSettingsChange(GameSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
      // Update theme when settings change
      _currentTheme = _getThemeFromSettings(newSettings);
    });
    // Save settings
    _settingsRepository.saveSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Consumer<GameEngine>(
      builder: (context, engine, child) {
        return MaterialApp(
          title: 'Cribbage',
          theme: _currentTheme.toThemeData(),
          home: GameScreen(
            engine: engine,
            currentTheme: _currentTheme,
            onThemeChange: _handleThemeChange,
            currentSettings: _currentSettings,
            onSettingsChange: _handleSettingsChange,
          ),
        );
      },
    );
  }
}
