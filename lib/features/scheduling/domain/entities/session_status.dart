enum SessionStatus {
  requested,
  confirmed,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case SessionStatus.requested:
        return 'Requested';
      case SessionStatus.confirmed:
        return 'Confirmed';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}
