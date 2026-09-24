import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral.dart';
import 'package:elderly_companion/features/referrals/presentation/providers/referral_providers.dart';
import 'package:elderly_companion/features/referrals/presentation/widgets/inline_error.dart';

/// Owner: referrals (new, unassigned in the original team split, same as
/// `community`). Lets a signed-in user share their own code and, if they
/// haven't already, redeem someone else's.
class ReferralsScreen extends ConsumerWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Refer a friend')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return const EmptyView(
              icon: Icons.lock_outline,
              title: 'Sign in first',
              message: 'You need to be signed in to view your referral code.',
            );
          }
          return _ReferralsBody(userId: user.id);
        },
      ),
    );
  }
}

class _ReferralsBody extends ConsumerWidget {
  const _ReferralsBody({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _MyCodeCard(userId: userId),
        const SizedBox(height: AppSpacing.lg),
        _RedeemCodeCard(userId: userId),
        const SizedBox(height: AppSpacing.lg),
        _MyReferralsList(userId: userId),
      ],
    );
  }
}

class _MyCodeCard extends ConsumerWidget {
  const _MyCodeCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codeAsync = ref.watch(myReferralCodeProvider(userId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your referral code', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Share this with a friend or neighbour. When they sign up and '
            'enter it, you\'ll both show up in each other\'s referral history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          codeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => InlineError(message: error.toString()),
            data: (referralCode) => Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      referralCode.code,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copy code',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: referralCode.code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral code copied.')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemCodeCard extends ConsumerStatefulWidget {
  const _RedeemCodeCard({required this.userId});

  final String userId;

  @override
  ConsumerState<_RedeemCodeCard> createState() => _RedeemCodeCardState();
}

class _RedeemCodeCardState extends ConsumerState<_RedeemCodeCard> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = ref.read(profileProvider(widget.userId)).valueOrNull;
    final referredName = profile?.displayName ?? widget.userId;

    setState(() => _isSubmitting = true);
    final result = await ref.read(redeemReferralCodeUseCaseProvider).call(
          code: _controller.text.trim(),
          referredUserId: widget.userId,
          referredName: referredName,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral code redeemed!')),
        );
        ref.invalidate(hasRedeemedCodeProvider(widget.userId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRedeemedAsync = ref.watch(hasRedeemedCodeProvider(widget.userId));

    return hasRedeemedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => AppCard(child: InlineError(message: error.toString())),
      data: (hasRedeemed) {
        if (hasRedeemed) {
          return AppCard(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(child: Text("You've already redeemed a referral code.")),
              ],
            ),
          );
        }
        return AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Have a code?', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter the code a friend shared with you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Referral code',
                  hint: 'e.g. 7K9P2M',
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a referral code.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Redeem',
                  icon: Icons.redeem_outlined,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyReferralsList extends ConsumerWidget {
  const _MyReferralsList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final referralsAsync = ref.watch(myReferralsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('People you\'ve referred', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        referralsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => InlineError(message: error.toString()),
          data: (referrals) {
            if (referrals.isEmpty) {
              return const EmptyView(
                icon: Icons.group_add_outlined,
                title: 'No referrals yet',
                message: 'Share your code to see who joins here.',
              );
            }
            return Column(
              children: [
                for (final referral in referrals) _ReferralTile(referral: referral),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReferralTile extends StatelessWidget {
  const _ReferralTile({required this.referral});

  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              child: Text(
                referral.referredName.trim().isEmpty
                    ? '?'
                    : referral.referredName.trim()[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(referral.referredName, style: theme.textTheme.titleMedium),
            ),
            Text(
              '${referral.createdAt.day}/${referral.createdAt.month}/${referral.createdAt.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
