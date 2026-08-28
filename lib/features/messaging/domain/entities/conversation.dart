/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/conversation_dto.dart) convert Firestore documents to
/// and from this type; nothing outside data/ should know Firestore exists.
///
/// One [Conversation] per unordered pair of participants — see
/// [MessagingRepository.getOrCreateConversation] for the deterministic
/// doc-ID scheme that enforces that invariant.
class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.createdAt,
  });

  final String id;

  /// Exactly the two participant UIDs.
  final List<String> participantIds;

  /// Preview text for the conversations list. Empty until the first
  /// message is sent.
  final String lastMessageText;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  /// The other participant's UID, given the signed-in user's own — `null`
  /// if [userId] isn't actually one of [participantIds].
  String? otherParticipantId(String userId) {
    for (final id in participantIds) {
      if (id != userId) return id;
    }
    return null;
  }

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    String? lastMessageText,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _listEquals(participantIds, other.participantIds) &&
          lastMessageText == other.lastMessageText &&
          lastMessageAt == other.lastMessageAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        Object.hashAll(participantIds),
        lastMessageText,
        lastMessageAt,
        createdAt,
      );
}

/// Hand-rolled rather than pulling in `package:collection`'s `ListEquality`
/// — matches the pattern in profiles/domain/entities/user_profile.dart.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
