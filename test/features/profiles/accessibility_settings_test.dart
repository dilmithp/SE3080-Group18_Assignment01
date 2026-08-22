import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';
import 'package:elderly_companion/features/profiles/presentation/screens/accessibility_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AccessibilitySettingsScreen renders text scale, contrast, and voice settings',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AccessibilitySettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Accessibility Settings'), findsOneWidget);
    expect(find.textContaining('Text Size'), findsOneWidget);
    expect(find.text('High Contrast Mode'), findsOneWidget);
    expect(find.text('Simplified Interface'), findsOneWidget);
    expect(find.text('Voice-Guided Prompts'), findsOneWidget);
    expect(find.text('Reset Accessibility Defaults'), findsOneWidget);
  });

  test('AccessibilityState copyWith and json serialization work correctly', () {
    const state = AccessibilityState(
      textScale: 1.3,
      highContrast: true,
      simplifiedMode: true,
      voiceGuidedPrompts: true,
    );

    final json = state.toJson();
    expect(json['textScale'], 1.3);
    expect(json['highContrast'], true);
    expect(json['simplifiedMode'], true);
    expect(json['voiceGuidedPrompts'], true);

    final restored = AccessibilityState.fromJson(json);
    expect(restored, state);
  });
}
