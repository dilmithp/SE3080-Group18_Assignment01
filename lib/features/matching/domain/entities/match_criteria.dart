/// Pure domain entity — zero `package:firebase_*` imports. Describes the
/// search parameters used to find [MatchCandidate]s for a given user.
class MatchCriteria {
  const MatchCriteria({
    required this.locality,
    required this.radiusKm,
    required this.requiredSkills,
    required this.preferredTimes,
  });

  final String locality;
  final double radiusKm;
  final List<String> requiredSkills;
  final List<String> preferredTimes;

  MatchCriteria copyWith({
    String? locality,
    double? radiusKm,
    List<String>? requiredSkills,
    List<String>? preferredTimes,
  }) {
    return MatchCriteria(
      locality: locality ?? this.locality,
      radiusKm: radiusKm ?? this.radiusKm,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      preferredTimes: preferredTimes ?? this.preferredTimes,
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
          _listEquals(preferredTimes, other.preferredTimes);

  @override
  int get hashCode => Object.hash(
        locality,
        radiusKm,
        Object.hashAll(requiredSkills),
        Object.hashAll(preferredTimes),
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
