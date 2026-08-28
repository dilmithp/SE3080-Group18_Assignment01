import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/extensions.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/messaging/domain/entities/conversation.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';
import 'package:elderly_companion/features/messaging/presentation/providers/messaging_providers.dart';

/// Every conversation the signed-in user is a participant of, most recently
/// active first. Tapping a row opens [ChatScreen] at `/chat/:conversationId`
/// (registered elsewhere — see this feature's integration report).
class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: currentUserId == null
          ? const EmptyView(
              icon: Icons.lock_outline,
              title: 'Sign in to view messages',
              message: 'You need to be signed in to see your conversations.',
            )
          : _ConversationsBody(currentUserId: currentUserId),
    );
  }
}

class _ConversationsBody extends ConsumerWidget {
  const _ConversationsBody({required this.currentUserId});

  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsForUserProvider(currentUserId));

    return conversationsAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (conversations) {
        if (conversations.isEmpty) {
          return const EmptyView(
            icon: Icons.forum_outlined,
            title: 'No conversations yet',
            message: 'Message a match from their profile to start chatting '
                'before or after a session.',
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final otherUserId = conversation.otherParticipantId(currentUserId);
                if (otherUserId == null) return const SizedBox.shrink();
                return _ConversationTile(
                  conversation: conversation,
                  otherUserId: otherUserId,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation, required this.otherUserId});

  final Conversation conversation;
  final String otherUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider(otherUserId)).valueOrNull;
    final displayName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Companion';
    final preview = conversation.lastMessageText.isEmpty
        ? 'Say hello to start the conversation'
        : conversation.lastMessageText;

    return AppCard(
      onTap: () => context.push('/chat/${conversation.id}', extra: otherUserId),
      child: Row(
        children: [
          _Avatar(photoUrl: profile?.photoUrl, displayName: displayName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  preview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: conversation.lastMessageText.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _relativeTime(conversation.lastMessageAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.displayName});

  final String? photoUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();

    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
      child: Text(
        initial,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Short relative-time label for a conversation row: "Just now" / "12m ago" /
/// "3h ago" / "Yesterday" / a weekday name within the last week / an
/// absolute date beyond that. Reuses [DateTimeFormatting.isSameDay] and
/// [DateTimeFormatting.toDisplayDate] from core/utils/extensions.dart.
String _relativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (dateTime.isSameDay(now)) return '${difference.inHours}h ago';

  final yesterday = now.subtract(const Duration(days: 1));
  if (dateTime.isSameDay(yesterday)) return 'Yesterday';
  if (difference.inDays < 7) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[dateTime.weekday - 1];
  }
  return dateTime.toDisplayDate();
}
