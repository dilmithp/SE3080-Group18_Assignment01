import 'package:elderly_companion/features/auth_trust/data/datasources/auth_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fallback = 'Sign-in failed.';

  group('friendlyAuthMessage', () {
    test('too-many-requests tells the user to wait or reset the password', () {
      expect(
        friendlyAuthMessage('too-many-requests', fallback),
        'Too many attempts. Wait a few minutes, or reset your password.',
      );
    });

    test('network-request-failed asks the user to check the connection', () {
      expect(
        friendlyAuthMessage('network-request-failed', fallback),
        'No network connection. Check your connection and try again.',
      );
    });

    test('user-disabled points the user to support', () {
      expect(
        friendlyAuthMessage('user-disabled', fallback),
        'This account has been disabled. Contact support.',
      );
    });

    test('unknown codes keep the fallback message', () {
      expect(friendlyAuthMessage('wrong-password', fallback), fallback);
    });

    test('a null code keeps the fallback message', () {
      expect(friendlyAuthMessage(null, fallback), fallback);
    });
  });
}
