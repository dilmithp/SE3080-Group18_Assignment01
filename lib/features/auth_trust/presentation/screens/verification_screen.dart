import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';

/// Placeholder screen — owner: Pathirana (features/auth_trust).
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  Future<void> _submitDocument(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final useCase = ref.read(submitVerificationRequestUseCaseProvider);
      await useCase(userId: 'current-user-id', documentUrl: 'placeholder-url');
    } on UnimplementedError catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message ?? 'Not implemented yet.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: EmptyView(
        icon: Icons.verified_user_outlined,
        message:
            'No verification request submitted yet.\nOwner: Pathirana — features/auth_trust',
        action: AppButton(
          label: 'Submit documents',
          onPressed: () => _submitDocument(context, ref),
        ),
      ),
    );
  }
}
