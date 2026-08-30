import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';

/// Pure domain entity — zero `package:firebase_*` imports. Describes the
/// search parameters used to find [MatchCandidate]s for a given user.
class MatchCriteria {
  const MatchCriteria({
    required this.locality,
    required this.radiusKm,
    required this.requiredSkills,
    required this.preferredTimes,
    required this.viewerId,
    required this.viewerRole,
    this.origin,
    this.strategyType = MatchingStrategyType.balanced,
  });

  final String locality;
  final double radiusKm;
  final List<String> requiredSkills;
  final List<String> preferredTimes;

  /// The searching user's own id, always excluded from their own results.
  final String viewerId;

  /// Who may see whom: elderly members only see volunteers; volunteers see
  /// both elderly members and other volunteers; admins see everyone.
  final UserRole viewerRole;

  /// The searching user's own coordinates, when known. Optional because
  /// not every caller has a resolved profile (e.g. a searcher who hasn't
  /// completed onboarding yet) — without it, real distance ranking is
  /// skipped and candidates fall back to locality-only matching.
  final GeoCoordinates? origin;

  /// Which [MatchingStrategy] [FindMatchesUseCase] ranks results with.
  final MatchingStrategyType strategyType;

  MatchCriteria copyWith({
    String? locality,
    double? radiusKm,
    List<String>? requiredSkills,
    List<String>? preferredTimes,
    String? viewerId,
    UserRole? viewerRole,
    GeoCoordinates? origin,
    MatchingStrategyType? strategyType,
  }) {
    return MatchCriteria(
      locality: locality ?? this.locality,
      radiusKm: radiusKm ?? this.radiusKm,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      viewerId: viewerId ?? this.viewerId,
      viewerRole: viewerRole ?? this.viewerRole,
      origin: origin ?? this.origin,
      strategyType: strategyType ?? this.strategyType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchCriteria &&
          runtimeType == other.runtimeType &&
          locality == other.locality &&
          radiusKm == other.radiusKm &&
          _listEquals(requiredSkills, other.requiredSkills) &&
          _listEquals(preferredTimes, other.preferredTimes) &&
          viewerId == other.viewerId &&
          viewerRole == other.viewerRole &&
          origin == other.origin &&
          strategyType == other.strategyType;

  @override
  int get hashCode => Object.hash(
        locality,
        radiusKm,
        Object.hashAll(requiredSkills),
        Object.hashAll(preferredTimes),
        viewerId,
        viewerRole,
        origin,
        strategyType,
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
