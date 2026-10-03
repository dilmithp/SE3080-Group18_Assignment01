import 'package:elderly_companion/core/routing/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeForNotification', () {
    test('a session reminder opens that session', () {
      expect(
        routeForNotification({'type': 'session_reminder', 'sessionId': 'abc123'}),
        '/scheduling/abc123',
      );
    });

    test('a session reminder without an id falls back to null', () {
      expect(routeForNotification({'type': 'session_reminder'}), isNull);
      expect(routeForNotification({'type': 'session_reminder', 'sessionId': ''}), isNull);
    });

    test('an id that could change the path is refused', () {
      expect(
        routeForNotification({'type': 'session_reminder', 'sessionId': '../admin'}),
        isNull,
      );
      expect(
        routeForNotification({'type': 'session_reminder', 'sessionId': 'a?b=c'}),
        isNull,
      );
    });

    test('verification results open the verification screen', () {
      expect(routeForNotification({'type': 'verification_approved'}), '/verification');
      expect(routeForNotification({'type': 'verification_rejected'}), '/verification');
    });

    test('a raw payload with non-string values still routes on its string fields', () {
      expect(
        routeForPushData({'type': 'session_reminder', 'sessionId': 'abc', 'count': 3}),
        '/scheduling/abc',
      );
    });

    test('an unknown type returns null', () {
      expect(routeForNotification({'type': 'something_new'}), isNull);
      expect(routeForNotification(const {}), isNull);
    });
  });
}
