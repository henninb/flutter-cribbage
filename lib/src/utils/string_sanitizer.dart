/// Utility class for sanitizing user input strings
class StringSanitizer {
  /// Maximum allowed length for player names
  static const int maxNameLength = 20;

  /// Minimum allowed length for player names
  static const int minNameLength = 1;

  /// Sanitizes a player name for safe display and storage
  ///
  /// - Trims leading and trailing whitespace
  /// - Limits length to [maxNameLength] characters
  /// - Removes or replaces potentially dangerous characters
  /// - Returns empty string if result is invalid
  ///
  /// For security:
  /// - Prevents XSS by removing HTML/script tags
  /// - Prevents injection attacks by limiting special characters
  /// - Ensures names display properly in UI
  static String sanitizeName(String input) {
    // Step 1: Trim whitespace
    var sanitized = input.trim();

    // Step 2: Remove any HTML tags (basic XSS prevention)
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Step 3: Remove control characters and other dangerous characters
    // Allow: letters, numbers, spaces, basic punctuation (._-')
    sanitized = sanitized.replaceAll(RegExp(r"[^\w\s._\-']"), '');

    // Step 4: Normalize multiple spaces to single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Step 5: Trim again after character removal
    sanitized = sanitized.trim();

    // Step 6: Enforce max length
    if (sanitized.length > maxNameLength) {
      sanitized = sanitized.substring(0, maxNameLength).trim();
    }

    // Step 7: Return empty string if too short (caller should handle)
    if (sanitized.length < minNameLength) {
      return '';
    }

    return sanitized;
  }

  /// Checks if a name is valid after sanitization
  static bool isValidName(String input) {
    final sanitized = sanitizeName(input);
    return sanitized.isNotEmpty;
  }

  /// Gets a sanitized name or returns a default if invalid
  static String sanitizeNameWithDefault(String input, String defaultName) {
    final sanitized = sanitizeName(input);
    return sanitized.isEmpty ? defaultName : sanitized;
  }
}
