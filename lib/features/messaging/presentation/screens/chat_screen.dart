import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/extensions.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/core/widgets/staggered_entrance.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/messaging/domain/entities/chat_message.dart';
import 'package:elderly_companion/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

/// One 1:1 conversation. [conversationId] is the deterministic doc ID (see
/// `MessagingRemoteDataSource.conversationIdFor`); [otherUserId] is who the
/// signed-in user is talking to, used to look up their name/photo for the
/// app bar and to tell "mine" bubbles from "theirs".
///
/// Registered elsewhere as `/chat/:conversationId` with [otherUserId]
/// arriving via the go_router `extra` payload — see this feature's
/// integration report for the exact `GoRoute` shape expected.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, required this.otherUserId, super.key});

  final String conversationId;
  final String otherUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send(String currentUserId) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    _textController.clear();
    setState(() => _isSending = true);
    try {
      final useCase = ref.read(sendMessageUseCaseProvider);
      final result = await useCase(
        conversationId: widget.conversationId,
        senderId: currentUserId,
        text: text,
      );
      result.fold(
        (failure) {
          // Restore the draft so a failed send doesn't lose what was typed.
          _textController.text = text;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failure.message)));
        },
        (_) {},
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;
    final otherProfile = ref.watch(profileProvider(widget.otherUserId)).valueOrNull;
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final title = otherProfile?.displayName.isNotEmpty == true
        ? otherProfile!.displayName
        : 'Chat';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: error.toString()),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const EmptyView(
                      icon: Icons.waving_hand_outlined,
                      title: 'Say hello',
                      message: 'Say hello to start the conversation.',
                    );
                  }
                  // Runs after every build of a non-empty list, including the
                  // first — harmless when already at the bottom, and keeps a
                  // newly arrived message in view without extra state.
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      // No stagger delay (always index 0): each bubble
                      // should pop in as soon as it mounts — a message that
                      // just arrived shouldn't wait its turn behind however
                      // many messages came before it in the conversation.
                      return StaggeredEntrance(
                        index: 0,
                        child: _MessageBubble(
                          message: message,
                          isMine: message.senderId == currentUserId,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Material(
              elevation: AppElevation.overlay,
              color: theme.colorScheme.surface,
              child: _Composer(
                controller: _textController,
                isSending: _isSending,
                onSend: currentUserId == null ? null : () => _send(currentUserId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        isMine ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final foreground =
        isMine ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.card),
              topRight: const Radius.circular(AppRadius.card),
              bottomLeft: Radius.circular(isMine ? AppRadius.card : AppRadius.small),
              bottomRight: Radius.circular(isMine ? AppRadius.small : AppRadius.card),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message.createdAt.toDisplayTime(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text input + send button pinned at the bottom of [ChatScreen]. The send
/// button's enabled state tracks [controller] via [ValueListenableBuilder]
/// so it only lights up once there is non-whitespace text to send.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AppTextField(
              label: 'Message',
              hint: 'Type a message',
              controller: controller,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              enabled: !isSending,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return Semantics(
                label: 'Send message',
                child: IconButton.filled(
                  iconSize: 26,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.send_rounded),
                  onPressed: (!hasText || isSending || onSend == null) ? null : onSend,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
