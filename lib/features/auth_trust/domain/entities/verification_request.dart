import 'package:elderly_companion/features/auth_trust/domain/entities/verification_status.dart';

/// Pure domain entity — zero `package:firebase_*` imports.
class VerificationRequest {
  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.documentUrl,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String userId;
  final String documentUrl;
  final VerificationStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? documentUrl,
    VerificationStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          documentUrl == other.documentUrl &&
          status == other.status &&
          reviewedBy == other.reviewedBy &&
          reviewedAt == other.reviewedAt;

  @override
  int get hashCode =>
      Object.hash(id, userId, documentUrl, status, reviewedBy, reviewedAt);
}
