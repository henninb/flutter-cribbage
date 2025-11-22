import 'package:flutter/material.dart';
import '../../models/theme_models.dart';
import '../theme/theme_definitions.dart';

/// Theme selector bar shown at top of screen
class ThemeSelectorBar extends StatelessWidget {
  final CribbageTheme currentTheme;
  final Function(CribbageTheme) onThemeSelected;
  final VoidCallback? onSettingsClick;

  const ThemeSelectorBar({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
    this.onSettingsClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Theme selector scroll area
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: ThemeDefinitions.allThemes.length,
              itemBuilder: (context, index) {
                final theme = ThemeDefinitions.allThemes[index];
                final isSelected = theme.type == currentTheme.type;

                return _ThemeButton(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () => onThemeSelected(theme),
                );
              },
            ),
          ),
          // Settings button
          if (onSettingsClick != null)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: onSettingsClick,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final CribbageTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  theme.icon,
                  style: TextStyle(
                    fontSize: isSelected ? 24 : 20,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    height: 2,
                    width: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
