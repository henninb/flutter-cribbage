import 'package:flutter_test/flutter_test.dart';
import 'package:cribbage/src/utils/string_sanitizer.dart';

void main() {
  group('StringSanitizer', () {
    group('sanitizeName', () {
      test('trims whitespace', () {
        expect(StringSanitizer.sanitizeName('  Alice  '), 'Alice');
        expect(StringSanitizer.sanitizeName('\tBob\n'), 'Bob');
      });

      test('removes HTML tags', () {
        expect(
          StringSanitizer.sanitizeName('<script>alert("xss")</script>Alice'),
          'alertxssAlice',
        );
        expect(StringSanitizer.sanitizeName('Bob<br>Smith'), 'BobSmith');
      });

      test('removes dangerous characters', () {
        expect(StringSanitizer.sanitizeName('Alice@#\$%'), 'Alice');
        expect(StringSanitizer.sanitizeName('Bob&Carol'), 'BobCarol');
        expect(StringSanitizer.sanitizeName('Player<>123'), 'Player123');
      });

      test('allows basic punctuation', () {
        expect(StringSanitizer.sanitizeName("Alice_Smith"), "Alice_Smith");
        expect(StringSanitizer.sanitizeName("Bob.Jones"), "Bob.Jones");
        expect(StringSanitizer.sanitizeName("Mary-Jane"), "Mary-Jane");
        expect(StringSanitizer.sanitizeName("O'Brien"), "O'Brien");
      });

      test('normalizes multiple spaces', () {
        expect(
          StringSanitizer.sanitizeName('Alice    Bob'),
          'Alice Bob',
        );
        expect(
          StringSanitizer.sanitizeName('Player   123'),
          'Player 123',
        );
      });

      test('enforces max length', () {
        final longName = 'A' * 30;
        final result = StringSanitizer.sanitizeName(longName);
        expect(result.length, StringSanitizer.maxNameLength);
        expect(result, 'A' * StringSanitizer.maxNameLength);
      });

      test('returns empty string for invalid names', () {
        expect(StringSanitizer.sanitizeName(''), '');
        expect(StringSanitizer.sanitizeName('   '), '');
        expect(StringSanitizer.sanitizeName('@#\$%'), '');
      });

      test('handles mixed valid and invalid characters', () {
        expect(StringSanitizer.sanitizeName('Alice!@# 123'), 'Alice 123');
        expect(StringSanitizer.sanitizeName('Bob<tag>Test'), 'BobTest');
        expect(StringSanitizer.sanitizeName('Player!@#123'), 'Player123');
      });

      test('handles unicode characters', () {
        // Unicode letters should be kept (if they match \w pattern)
        expect(
          StringSanitizer.sanitizeName('José'),
          'Jos',
        ); // é might be removed depending on regex
        expect(StringSanitizer.sanitizeName('Alice123'), 'Alice123');
      });
    });

    group('isValidName', () {
      test('returns true for valid names', () {
        expect(StringSanitizer.isValidName('Alice'), true);
        expect(StringSanitizer.isValidName('Bob_123'), true);
        expect(StringSanitizer.isValidName('Mary-Jane'), true);
      });

      test('returns false for invalid names', () {
        expect(StringSanitizer.isValidName(''), false);
        expect(StringSanitizer.isValidName('   '), false);
        expect(StringSanitizer.isValidName('@#\$%'), false);
      });
    });

    group('sanitizeNameWithDefault', () {
      test('returns sanitized name when valid', () {
        expect(
          StringSanitizer.sanitizeNameWithDefault('Alice', 'Default'),
          'Alice',
        );
        expect(
          StringSanitizer.sanitizeNameWithDefault('  Bob  ', 'Default'),
          'Bob',
        );
      });

      test('returns default when name is invalid', () {
        expect(
          StringSanitizer.sanitizeNameWithDefault('', 'Default'),
          'Default',
        );
        expect(
          StringSanitizer.sanitizeNameWithDefault('   ', 'Default'),
          'Default',
        );
        expect(
          StringSanitizer.sanitizeNameWithDefault('@#\$%', 'Default'),
          'Default',
        );
      });
    });

    group('constants', () {
      test('maxNameLength is reasonable', () {
        expect(StringSanitizer.maxNameLength, 20);
      });

      test('minNameLength is positive', () {
        expect(StringSanitizer.minNameLength, 1);
      });
    });
  });
}
