/// Pure domain entity — zero `package:firebase_*` imports. One record per
/// successful redemption of a [ReferralCode].
class Referral {
  const Referral({
    required this.id,
    required this.code,
    required this.referrerId,
    required this.referredUserId,
    required this.referredName,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String referrerId;
  final String referredUserId;

  /// Denormalized at redemption time so the referrer's "people you've
  /// referred" list doesn't need an extra read per row.
  final String referredName;

  final DateTime createdAt;

  Referral copyWith({
    String? id,
    String? code,
    String? referrerId,
    String? referredUserId,
    String? referredName,
    DateTime? createdAt,
  }) {
    return Referral(
      id: id ?? this.id,
      code: code ?? this.code,
      referrerId: referrerId ?? this.referrerId,
      referredUserId: referredUserId ?? this.referredUserId,
      referredName: referredName ?? this.referredName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Referral &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          referrerId == other.referrerId &&
          referredUserId == other.referredUserId &&
          referredName == other.referredName &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, code, referrerId, referredUserId, referredName, createdAt);
}
