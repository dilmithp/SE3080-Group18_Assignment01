import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/widgets/empty_view.dart';

/// Placeholder screen — owner: Perera (features/profiles).
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: const EmptyView(
        icon: Icons.edit_outlined,
        message: 'Edit profile — Owner: Perera — features/profiles',
      ),
    );
  }
}
