/// Pure domain entity — zero `package:firebase_*` imports. One per user,
/// created lazily the first time they open the referral screen.
class ReferralCode {
  const ReferralCode({
    required this.code,
    required this.ownerId,
    required this.createdAt,
  });

  final String code;
  final String ownerId;
  final DateTime createdAt;

  ReferralCode copyWith({
    String? code,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return ReferralCode(
      code: code ?? this.code,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralCode &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          ownerId == other.ownerId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(code, ownerId, createdAt);
}
