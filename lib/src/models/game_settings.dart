import 'theme_models.dart';

/// Card selection method
enum CardSelectionMode {
  tap, // Single tap to select (default)
  longPress, // Long press to select
  drag, // Drag to discard area
}

/// Counting mode for game scoring
enum CountingMode {
  automatic, // App calculates points automatically (default)
  manual, // Player inputs points manually (deferred - not yet implemented)
}

/// Game settings data class
class GameSettings {
  final CardSelectionMode cardSelectionMode;
  final CountingMode countingMode;
  final ThemeType? selectedTheme; // null means use date-based theme

  const GameSettings({
    this.cardSelectionMode = CardSelectionMode.tap,
    this.countingMode = CountingMode.automatic,
    this.selectedTheme, // null by default for date-based theme
  });

  /// Copy with method for immutable updates
  GameSettings copyWith({
    CardSelectionMode? cardSelectionMode,
    CountingMode? countingMode,
    ThemeType? selectedTheme,
    bool clearSelectedTheme = false,
  }) {
    return GameSettings(
      cardSelectionMode: cardSelectionMode ?? this.cardSelectionMode,
      countingMode: countingMode ?? this.countingMode,
      selectedTheme:
          clearSelectedTheme ? null : (selectedTheme ?? this.selectedTheme),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'cardSelectionMode': cardSelectionMode.name,
      'countingMode': countingMode.name,
      'selectedTheme': selectedTheme?.name,
    };
  }

  /// Create from JSON
  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      cardSelectionMode: CardSelectionMode.values.firstWhere(
        (e) => e.name == json['cardSelectionMode'],
        orElse: () => CardSelectionMode.tap,
      ),
      countingMode: CountingMode.values.firstWhere(
        (e) => e.name == json['countingMode'],
        orElse: () => CountingMode.automatic,
      ),
      selectedTheme: json['selectedTheme'] != null
          ? ThemeType.values.firstWhere(
              (e) => e.name == json['selectedTheme'],
              orElse: () => ThemeType.spring,
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSettings &&
        other.cardSelectionMode == cardSelectionMode &&
        other.countingMode == countingMode &&
        other.selectedTheme == selectedTheme;
  }

  @override
  int get hashCode =>
      Object.hash(cardSelectionMode, countingMode, selectedTheme);
}
