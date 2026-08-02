import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';

/// Placeholder screen — owner: Perera (features/profiles).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: EmptyView(
        icon: Icons.person_outline,
        message: 'Profile — Owner: Perera',
        action: AppButton(
          label: 'Edit profile',
          onPressed: () => context.push(RouteNames.editProfile),
        ),
      ),
    );
  }
}
