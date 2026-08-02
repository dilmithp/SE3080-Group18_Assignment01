enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending review';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}
