import 'package:elderly_companion/core/theme/app_theme.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the theme-level half of Simplified Mode's design-system
/// foundation: AppButton takes no code of its own to respond to
/// simplifiedMode (see app_theme.dart), so what needs verifying is that
/// AppTheme.light(simplifiedMode: true) actually resolves a taller minimum
/// tap target than the standard theme does — checked via the resolved
/// ElevatedButton style rather than rendered pixels, since a lone button in
/// an unconstrained Scaffold body doesn't reliably lay out at exactly its
/// minimumSize.
Future<double> _pumpButtonMinHeight(WidgetTester tester, {required bool simplified}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(simplifiedMode: simplified),
      home: Scaffold(
        body: AppButton(label: 'Find matches', onPressed: () {}),
      ),
    ),
  );
  // MaterialApp cross-fades theme changes via AnimatedTheme; pumping this
  // widget a second time (as the two calls in the test below do) reuses the
  // same MaterialApp element, so without settling, Theme.of(context) would
  // read a value still mid-transition from the first pump's theme.
  await tester.pumpAndSettle();
  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  final minimumSize = button.style?.minimumSize?.resolve(<WidgetState>{}) ??
      Theme.of(tester.element(find.byType(ElevatedButton)))
          .elevatedButtonTheme
          .style
          ?.minimumSize
          ?.resolve(<WidgetState>{});
  return minimumSize!.height;
}

void main() {
  testWidgets('AppButton resolves a taller minimum tap target in simplified mode',
      (tester) async {
    final standardHeight = await _pumpButtonMinHeight(tester, simplified: false);
    final simplifiedHeight = await _pumpButtonMinHeight(tester, simplified: true);

    expect(standardHeight, AppTheme.minTapTarget);
    expect(simplifiedHeight, AppTheme.minTapTargetSimplified);
    expect(simplifiedHeight, greaterThan(standardHeight));
  });
}
