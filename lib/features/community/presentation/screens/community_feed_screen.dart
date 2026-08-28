import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/community/domain/entities/community_post.dart';
import 'package:elderly_companion/features/community/presentation/providers/community_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

/// Owner: community (new, unassigned in the original team split). A shared
/// space for thank-yous, updates and requests — reinforcing the trust/
/// companionship theme beyond 1:1 sessions. Standalone: no other screen
/// links here yet, see the report from this feature's build for the route
/// and home-screen nav tile a later pass wires up.
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return const EmptyView(
              icon: Icons.lock_outline,
              title: 'Sign in first',
              message: 'You need to be signed in to see the community feed.',
            );
          }
          return _CommunityFeedBody(userId: user.id, fallbackAuthorName: user.email);
        },
      ),
      floatingActionButton: authState.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openNewPostSheet(
                context,
                userId: authState.valueOrNull!.id,
                fallbackAuthorName: authState.valueOrNull!.email,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New post'),
            ),
    );
  }

  void _openNewPostSheet(
    BuildContext context, {
    required String userId,
    required String fallbackAuthorName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _NewPostSheet(
        userId: userId,
        fallbackAuthorName: fallbackAuthorName,
      ),
    );
  }
}

class _CommunityFeedBody extends ConsumerWidget {
  const _CommunityFeedBody({required this.userId, required this.fallbackAuthorName});

  final String userId;
  final String fallbackAuthorName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return feedAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (posts) {
        if (posts.isEmpty) {
          return const EmptyView(
            icon: Icons.forum_outlined,
            title: 'Nothing here yet',
            message: 'Be the first to share something',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) =>
              _PostCard(post: posts[index], currentUserId: userId),
        );
      },
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.currentUserId});

  final CommunityPost post;
  final String currentUserId;

  bool get _isOwnPost => post.authorId == currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: post.authorName, photoUrl: post.authorPhotoUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.authorName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _relativeTime(post.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(post.text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          if (_isOwnPost) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete post',
              color: theme.colorScheme.error,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(deletePostUseCaseProvider).call(
          postId: post.id,
          authorId: currentUserId,
        );
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {},
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 24,
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
      child: photoUrl == null ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)) : null,
    );
  }
}

/// Short, plain-language relative timestamp ("Just now", "5m ago",
/// "3h ago", "2d ago"), falling back to an absolute date once a post is
/// more than a week old rather than showing an ever-growing day count.
String _relativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

class _NewPostSheet extends ConsumerStatefulWidget {
  const _NewPostSheet({required this.userId, required this.fallbackAuthorName});

  final String userId;
  final String fallbackAuthorName;

  @override
  ConsumerState<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends ConsumerState<_NewPostSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String authorName, String? authorPhotoUrl) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final result = await ref.read(createPostUseCaseProvider).call(
          authorId: widget.userId,
          authorName: authorName,
          authorPhotoUrl: authorPhotoUrl,
          text: _controller.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(widget.userId));
    final authorName = profileAsync.valueOrNull?.displayName ?? widget.fallbackAuthorName;
    final authorPhotoUrl = profileAsync.valueOrNull?.photoUrl;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share something', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Posting as $authorName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Your message',
              hint: 'A thank-you, an update, or a request for help…',
              controller: _controller,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Write something before posting.';
                }
                if (value.trim().length > 1000) {
                  return 'Keep posts under 1000 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Post',
              icon: Icons.send_outlined,
              isLoading: _isSubmitting,
              onPressed: () => _submit(authorName, authorPhotoUrl),
            ),
          ],
        ),
      ),
    );
  }
}
