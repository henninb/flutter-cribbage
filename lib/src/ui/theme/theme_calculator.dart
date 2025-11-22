import '../../models/theme_models.dart';
import 'theme_definitions.dart';

/// Determines the current theme based on today's date
class ThemeCalculator {
  /// Get the current theme based on the given date
  static CribbageTheme getCurrentTheme([DateTime? date]) {
    final now = date ?? DateTime.now();

    // Check holidays first (they override seasons)
    final holidayTheme = _getHolidayTheme(now);
    if (holidayTheme != null) {
      return holidayTheme;
    }

    // Fall back to seasonal theme
    return _getSeasonalTheme(now);
  }

  /// Check if the date matches a holiday theme
  static CribbageTheme? _getHolidayTheme(DateTime date) {
    final month = date.month;
    final day = date.day;

    // New Year's Day (Jan 1) - extended to Jan 1-3
    if (month == 1 && day >= 1 && day <= 3) {
      return ThemeDefinitions.newYear;
    }

    // MLK Day (3rd Monday in January)
    if (month == 1 && _isNthWeekdayOfMonth(date, DateTime.monday, 3)) {
      return ThemeDefinitions.mlkDay;
    }

    // Valentine's Day (Feb 14) - extended to Feb 12-16
    if (month == 2 && day >= 12 && day <= 16) {
      return ThemeDefinitions.valentinesDay;
    }

    // Presidents' Day (3rd Monday in February)
    if (month == 2 && _isNthWeekdayOfMonth(date, DateTime.monday, 3)) {
      return ThemeDefinitions.presidentsDay;
    }

    // Pi Day (Mar 14)
    if (month == 3 && day == 14) {
      return ThemeDefinitions.piDay;
    }

    // Ides of March (Mar 15)
    if (month == 3 && day == 15) {
      return ThemeDefinitions.idesOfMarch;
    }

    // St. Patrick's Day (Mar 17) - extended to Mar 16-18
    if (month == 3 && day >= 16 && day <= 18) {
      return ThemeDefinitions.stPatricksDay;
    }

    // Memorial Day (Last Monday in May)
    if (month == 5 && _isLastWeekdayOfMonth(date, DateTime.monday)) {
      return ThemeDefinitions.memorialDay;
    }

    // Independence Day (Jul 4) - extended to Jul 2-6
    if (month == 7 && day >= 2 && day <= 6) {
      return ThemeDefinitions.independenceDay;
    }

    // Labor Day (1st Monday in September)
    if (month == 9 && _isNthWeekdayOfMonth(date, DateTime.monday, 1)) {
      return ThemeDefinitions.laborDay;
    }

    // Halloween (Oct 31) - extended to Oct 28-31
    if (month == 10 && day >= 28 && day <= 31) {
      return ThemeDefinitions.halloween;
    }

    // Thanksgiving (4th Thursday in November)
    if (month == 11 && _isNthWeekdayOfMonth(date, DateTime.thursday, 4)) {
      return ThemeDefinitions.thanksgiving;
    }

    // Christmas (Dec 25) - extended to Dec 22-26
    if (month == 12 && day >= 22 && day <= 26) {
      return ThemeDefinitions.christmas;
    }

    return null;
  }

  /// Get seasonal theme based on date
  static CribbageTheme _getSeasonalTheme(DateTime date) {
    final month = date.month;
    final day = date.day;

    // Spring: March 20 - June 20
    if ((month == 3 && day >= 20) ||
        month == 4 ||
        month == 5 ||
        (month == 6 && day <= 20)) {
      return ThemeDefinitions.spring;
    }

    // Summer: June 21 - September 21
    if ((month == 6 && day >= 21) ||
        month == 7 ||
        month == 8 ||
        (month == 9 && day <= 21)) {
      return ThemeDefinitions.summer;
    }

    // Fall: September 22 - December 20
    if ((month == 9 && day >= 22) ||
        month == 10 ||
        month == 11 ||
        (month == 12 && day <= 20)) {
      return ThemeDefinitions.fall;
    }

    // Winter: December 21 - March 19
    return ThemeDefinitions.winter;
  }

  /// Check if date is the nth occurrence of a weekday in its month
  static bool _isNthWeekdayOfMonth(DateTime date, int weekday, int n) {
    if (date.weekday != weekday) return false;

    // Count how many times this weekday has occurred in the month up to this date
    int count = 0;
    for (int day = 1; day <= date.day; day++) {
      final checkDate = DateTime(date.year, date.month, day);
      if (checkDate.weekday == weekday) {
        count++;
      }
    }

    return count == n;
  }

  /// Check if date is the last occurrence of a weekday in its month
  static bool _isLastWeekdayOfMonth(DateTime date, int weekday) {
    if (date.weekday != weekday) return false;

    // Check if there are any more occurrences of this weekday in the month
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
    for (int day = date.day + 1; day <= lastDayOfMonth; day++) {
      final checkDate = DateTime(date.year, date.month, day);
      if (checkDate.weekday == weekday) {
        return false; // Found another occurrence
      }
    }

    return true; // This is the last occurrence
  }
}
