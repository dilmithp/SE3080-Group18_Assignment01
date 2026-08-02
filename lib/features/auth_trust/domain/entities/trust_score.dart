/// Pure domain entity — zero `package:firebase_*` imports.
class TrustScore {
  const TrustScore({
    required this.userId,
    required this.score,
    required this.completedSessions,
    required this.averageRating,
    required this.lastUpdated,
  });

  final String userId;
  final double score;
  final int completedSessions;
  final double averageRating;
  final DateTime lastUpdated;

  TrustScore copyWith({
    String? userId,
    double? score,
    int? completedSessions,
    double? averageRating,
    DateTime? lastUpdated,
  }) {
    return TrustScore(
      userId: userId ?? this.userId,
      score: score ?? this.score,
      completedSessions: completedSessions ?? this.completedSessions,
      averageRating: averageRating ?? this.averageRating,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrustScore &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          score == other.score &&
          completedSessions == other.completedSessions &&
          averageRating == other.averageRating &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      Object.hash(userId, score, completedSessions, averageRating, lastUpdated);
}
