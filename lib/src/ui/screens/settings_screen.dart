import 'package:flutter/material.dart';
import '../../models/game_settings.dart';
import '../../models/theme_models.dart';
import '../theme/theme_definitions.dart';

/// Settings screen overlay
class SettingsScreen extends StatelessWidget {
  final GameSettings currentSettings;
  final Function(GameSettings) onSettingsChange;
  final VoidCallback onBackPressed;

  const SettingsScreen({
    super.key,
    required this.currentSettings,
    required this.onSettingsChange,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Theme'),
          _buildThemeDropdown(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Card Selection'),
          _buildCardSelectionModeOption(
            context,
            CardSelectionMode.tap,
            'Tap',
            'Single tap to select cards',
            Icons.touch_app,
          ),
          _buildCardSelectionModeOption(
            context,
            CardSelectionMode.longPress,
            'Long Press',
            'Press and hold to select cards',
            Icons.touch_app_outlined,
          ),
          _buildCardSelectionModeOption(
            context,
            CardSelectionMode.drag,
            'Drag',
            'Drag cards to play area',
            Icons.drag_indicator,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Counting Mode'),
          _buildCountingModeOption(
            context,
            CountingMode.automatic,
            'Automatic',
            'App calculates points automatically',
            Icons.calculate,
          ),
          _buildCountingModeOption(
            context,
            CountingMode.manual,
            'Manual',
            'Enter points manually (Coming Soon)',
            Icons.edit,
            enabled: false, // Deferred feature
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeDropdown(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ThemeType?>(
            isExpanded: true,
            value: currentSettings.selectedTheme,
            icon: const Icon(Icons.arrow_drop_down),
            items: [
              // Date-based option
              DropdownMenuItem<ThemeType?>(
                value: null,
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Auto (Date-Based)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Theme changes based on current date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Theme options
              ...ThemeDefinitions.allThemes.map((theme) {
                return DropdownMenuItem<ThemeType?>(
                  value: theme.type,
                  child: Row(
                    children: [
                      Text(theme.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(theme.name),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (ThemeType? newTheme) {
              onSettingsChange(
                currentSettings.copyWith(
                  selectedTheme: newTheme,
                  clearSelectedTheme: newTheme == null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardSelectionModeOption(
    BuildContext context,
    CardSelectionMode mode,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = currentSettings.cardSelectionMode == mode;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () {
          if (mode != currentSettings.cardSelectionMode) {
            onSettingsChange(
              currentSettings.copyWith(cardSelectionMode: mode),
            );
          }
        },
      ),
    );
  }

  Widget _buildCountingModeOption(
    BuildContext context,
    CountingMode mode,
    String title,
    String description,
    IconData icon, {
    bool enabled = true,
  }) {
    final isSelected = currentSettings.countingMode == mode;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : enabled
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          icon,
          color: enabled
              ? (isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: enabled
            ? () {
                if (mode != currentSettings.countingMode) {
                  onSettingsChange(
                    currentSettings.copyWith(countingMode: mode),
                  );
                }
              }
            : null,
      ),
    );
  }
}
