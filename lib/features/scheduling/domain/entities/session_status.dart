/// The booking lifecycle: `requested → confirmed → completed`, with
/// `cancelled` reachable from either open state.
///
/// The legal edges are declared once, here, instead of as `if` checks
/// spread across the screens and use cases that trigger transitions. A new
/// rule (say, a `noShow` state) is then a change to [_allowedTransitions]
/// plus a new enum value — not a conditional bolted onto every caller.
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

  /// Edges out of each state. Every value has an entry — an empty set means
  /// the state is terminal, so [allowedNextStatuses] never has to guess.
  static const Map<SessionStatus, Set<SessionStatus>> _allowedTransitions = {
    SessionStatus.requested: {SessionStatus.confirmed, SessionStatus.cancelled},
    SessionStatus.confirmed: {SessionStatus.completed, SessionStatus.cancelled},
    SessionStatus.completed: <SessionStatus>{},
    SessionStatus.cancelled: <SessionStatus>{},
  };

  /// The states this one may move to. Empty for a terminal state.
  Set<SessionStatus> get allowedNextStatuses => _allowedTransitions[this]!;

  /// True once the session has settled — no further transition is legal.
  /// A completed session is not reopened and a cancelled one is rebooked as
  /// a new session, never revived.
  bool get isTerminal => allowedNextStatuses.isEmpty;

  /// Whether a session in this state may move to [next].
  ///
  /// Re-applying the current status is deliberately *not* a legal edge: a
  /// second tap on "Confirm" is a no-op for the caller to swallow, not a
  /// write worth sending to Firestore.
  bool canTransitionTo(SessionStatus next) => allowedNextStatuses.contains(next);
}
