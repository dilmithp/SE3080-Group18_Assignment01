import 'package:elderly_companion/core/utils/redact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactPersonalData', () {
    test('an email address is replaced', () {
      expect(
        redactPersonalData('Could not reach mary.silva@example.com'),
        'Could not reach [email]',
      );
    });

    test('a phone number is replaced', () {
      expect(redactPersonalData('Call 0771234567 now'), 'Call [phone] now');
      expect(redactPersonalData('Call +94 77 123 4567 now'), 'Call [phone] now');
    });

    test('text with no personal data is unchanged', () {
      const message = 'Network request failed on the session screen';
      expect(redactPersonalData(message), message);
    });
  });
}
