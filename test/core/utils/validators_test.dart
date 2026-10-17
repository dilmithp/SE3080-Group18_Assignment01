import 'package:elderly_companion/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.optionalPhone', () {
    test('a blank value is valid — the field is optional', () {
      expect(Validators.optionalPhone(null), isNull);
      expect(Validators.optionalPhone(''), isNull);
      expect(Validators.optionalPhone('   '), isNull);
    });

    test('a valid international number passes', () {
      expect(Validators.optionalPhone('+94712345678'), isNull);
    });

    test('a malformed number is rejected', () {
      expect(Validators.optionalPhone('not a phone number'), isNotNull);
    });
  });

  group('Validators.maxLength', () {
    test('a blank value is valid — required() is a separate check', () {
      expect(Validators.maxLength(null, 10), isNull);
      expect(Validators.maxLength('', 10), isNull);
    });

    test('a value within the limit is valid', () {
      expect(Validators.maxLength('short', 10), isNull);
    });

    test('a value over the limit is rejected with the English fallback', () {
      expect(Validators.maxLength('this is too long', 5), isNotNull);
    });

    test('a supplied message builder is used instead of the fallback', () {
      final result = Validators.maxLength(
        'this is too long',
        5,
        message: (max) => 'custom message with max $max',
      );
      expect(result, 'custom message with max 5');
    });
  });

  group('Validators.tagList', () {
    test('a blank value is valid', () {
      expect(Validators.tagList(null), isNull);
      expect(Validators.tagList(''), isNull);
    });

    test('tags within both limits are valid', () {
      expect(Validators.tagList('gardening, cooking, tech help'), isNull);
    });

    test('too many tags is rejected', () {
      final tags = List.generate(5, (i) => 'tag$i').join(', ');
      expect(Validators.tagList(tags, maxCount: 3), isNotNull);
    });

    test('a single tag that is too long is rejected', () {
      final longTag = 'a' * 60;
      expect(Validators.tagList(longTag, maxTagLength: 50), isNotNull);
    });

    test('blank entries between commas are ignored, not counted as tags', () {
      expect(Validators.tagList('gardening, , cooking', maxCount: 2), isNull);
    });

    test('supplied message builders are used instead of the English fallback', () {
      final tooMany = Validators.tagList(
        'a, b, c',
        maxCount: 2,
        tooManyMessage: (max) => 'too many, max $max',
      );
      expect(tooMany, 'too many, max 2');

      final tooLong = Validators.tagList(
        'a' * 60,
        maxTagLength: 50,
        tagTooLongMessage: (max) => 'too long, max $max',
      );
      expect(tooLong, 'too long, max 50');
    });
  });
}
