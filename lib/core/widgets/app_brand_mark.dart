import 'package:flutter/material.dart';

/// The app's logo mark: the brand icon seated on a warm tinted squircle.
///
/// Shared by the splash and the auth screens so the app's front door presents
/// one consistent identity rather than three near-misses.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({this.size = 112, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(size * 0.29)),
        border: Border.all(color: scheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.volunteer_activism,
        size: size * 0.5,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
