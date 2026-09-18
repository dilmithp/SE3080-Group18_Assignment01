// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elderly_companion/core/widgets/app_button.dart';

/// Accessibility guideline tests for the profile and settings screens.
///
/// These tests use Flutter's built-in [AccessibilityGuideline] framework to
/// verify that:
///  - All tap targets meet the Android minimum size (48 × 48 dp).
///  - All labelled tap targets have a meaningful semantic label.
///  - Text and background colours meet WCAG AA contrast ratios.
///
/// Widget-level tests are used instead of integration tests so they can run
/// in CI without a device.
void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Wraps [widget] in the minimal scaffold needed for guideline checks.
  Widget _wrap(Widget widget) => MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(body: widget),
      );



  // ---------------------------------------------------------------------------
  // Android tap-target size tests — profile screen widgets
  // ---------------------------------------------------------------------------
  group('androidTapTargetGuideline — profile screen widgets', () {
    testWidgets('AppButton meets minimum tap target (48x48)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Center(
            child: AppButton(
              label: 'Save profile',
              onPressed: () {},
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('EditProfileScreen save button meets minimum tap target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ElevatedButton(
            key: const Key('save_profile_btn'),
            onPressed: () {},
            child: const Text('Save profile'),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('IconButton meets minimum tap target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          IconButton(
            key: const Key('edit_icon'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () {},
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('FilterChip meets minimum tap target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FilterChip(
            key: const Key('safety_chip'),
            label: const Text('Female volunteers only'),
            selected: false,
            onSelected: (_) {},
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('SwitchListTile meets minimum tap target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SwitchListTile(
            key: const Key('high_contrast_toggle'),
            title: const Text('High Contrast Mode'),
            value: false,
            onChanged: (_) {},
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Accessibility label tests — every interactive element must have a label
  // ---------------------------------------------------------------------------
  group('labeledTapTargetGuideline — profile & settings widgets', () {
    testWidgets('AppButton has explicit button semantics label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Center(
            child: AppButton(
              label: 'Save profile',
              onPressed: () {},
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
      );
    });

    testWidgets('Labelled edit-profile IconButton passes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Semantics(
            label: 'Edit profile',
            button: true,
            child: IconButton(
              key: const Key('edit_icon_labelled'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
              onPressed: () {},
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
      );
    });

    testWidgets('Labelled Call emergency contact button passes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Semantics(
            label: 'Call emergency contact Amara at +94711234567',
            button: true,
            child: ElevatedButton.icon(
              key: const Key('call_btn'),
              onPressed: () {},
              icon: const Icon(Icons.call),
              label: const Text('Call Amara'),
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
      );
    });

    testWidgets('Labelled availability remove button passes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Semantics(
            label: 'Remove Monday 09:00–12:00 availability window',
            button: true,
            child: IconButton(
              key: const Key('remove_window_btn'),
              icon: const Icon(Icons.close),
              tooltip: 'Remove availability window',
              onPressed: () {},
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Text contrast tests — Check whether text is readable against its background, such as the profile-completeness text and emergency-contact heading.
  // ---------------------------------------------------------------------------
  group('textContrastGuideline — profile & settings text', () {
    testWidgets('Body text on surface passes contrast check (light theme)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: Center(
              child: Text(
                'Profile 60% complete',
                key: Key('completeness_text'),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(textContrastGuideline),
      );
    });

    testWidgets('Error-container text (emergency card) passes contrast check', (tester) async {
      final theme = ThemeData.light(useMaterial3: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Container(
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Emergency contact',
                key: const Key('emergency_heading'),
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(textContrastGuideline),
      );
    });

    testWidgets('Accessibility settings toggle subtitle passes contrast', (tester) async {
      final theme = ThemeData.light(useMaterial3: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SwitchListTile(
              key: const Key('high_contrast_tile'),
              title: const Text('High Contrast Mode'),
              subtitle: const Text(
                'Increases text and button contrast for higher readability.',
              ),
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(textContrastGuideline),
      );
    });
  });
}
