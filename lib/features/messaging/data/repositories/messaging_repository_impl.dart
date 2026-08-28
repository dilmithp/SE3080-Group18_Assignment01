import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/messaging/data/datasources/messaging_remote_data_source.dart';
import 'package:elderly_companion/features/messaging/domain/entities/chat_message.dart';
import 'package:elderly_companion/features/messaging/domain/entities/conversation.dart';
import 'package:elderly_companion/features/messaging/domain/repositories/messaging_repository.dart';

/// Satisfies [MessagingRepository] by delegating to [_dataSource] and
/// mapping data-layer exceptions to [Failure]s — see
/// auth_trust/data/repositories/verification_repository_impl.dart for the
/// exact exception -> Failure shape this copies.
class MessagingRepositoryImpl implements MessagingRepository {
  const MessagingRepositoryImpl(this._dataSource);

  final MessagingRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, Conversation>> getOrCreateConversation({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final dto = await _dataSource.getOrCreateConversation(
        userId: userId,
        otherUserId: otherUserId,
      );
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<List<Conversation>> watchConversationsForUser(String userId) {
    // Most recently active conversation first — Firestore returns query
    // results unordered here (no composite index for this yet), so the
    // ordering the conversations list screen needs is applied client-side.
    return _dataSource.watchConversationsForUser(userId).map(
          (dtos) => dtos.map((d) => d.toEntity()).toList()
            ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt)),
        );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _dataSource
        .watchMessages(conversationId)
        .map((dtos) => dtos.map((d) => d.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _dataSource.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: text,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
