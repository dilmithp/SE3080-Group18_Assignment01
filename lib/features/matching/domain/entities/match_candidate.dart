import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';

/// Pure domain entity — zero `package:firebase_*` imports. Importing
/// [UserProfile] from the profiles feature's pure domain layer is fine
/// (it carries no Firebase types either); importing anything from
/// `package:firebase_*` or `package:cloud_firestore` here would not be.
/// Data-layer DTOs (see data/models/match_candidate_dto.dart) convert
/// Firestore documents to and from this type.
class MatchCandidate {
  const MatchCandidate({
    required this.userId,
    required this.profile,
    required this.distanceKm,
    required this.trustScore,
    required this.matchScore,
    required this.matchReasons,
  });

  final String userId;
  final UserProfile profile;
  final double distanceKm;
  final double trustScore;
  final double matchScore;
  final List<String> matchReasons;

  MatchCandidate copyWith({
    String? userId,
    UserProfile? profile,
    double? distanceKm,
    double? trustScore,
    double? matchScore,
    List<String>? matchReasons,
  }) {
    return MatchCandidate(
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
      distanceKm: distanceKm ?? this.distanceKm,
      trustScore: trustScore ?? this.trustScore,
      matchScore: matchScore ?? this.matchScore,
      matchReasons: matchReasons ?? this.matchReasons,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchCandidate &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          profile == other.profile &&
          distanceKm == other.distanceKm &&
          trustScore == other.trustScore &&
          matchScore == other.matchScore &&
          _listEquals(matchReasons, other.matchReasons);

  @override
  int get hashCode => Object.hash(
        userId,
        profile,
        distanceKm,
        trustScore,
        matchScore,
        Object.hashAll(matchReasons),
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
