/// Scheduling-specific data-layer exceptions.
///
/// The shared set in `core/error/exceptions.dart` has no conflict or
/// illegal-transition case, and adding one there is a change to a core file
/// (two teammate reviews, per CLAUDE.md). These live beside the data source
/// that throws them until that review happens; like every other data-layer
/// exception they are caught by the repository implementation and mapped to
/// a [Failure] — nothing above `data/` sees them.
///
/// Owner: Ranketh (features/scheduling).
library;

/// The slot was taken between the request being made and it being accepted.
class SessionConflictException implements Exception {
  const SessionConflictException([
    this.message = 'This time slot is no longer available.',
  ]);

  final String message;
}

/// The session was not in a state the requested transition allows — usually
/// because someone else already cancelled or confirmed it.
class InvalidSessionTransitionException implements Exception {
  const InvalidSessionTransitionException([
    this.message = 'This session can no longer be updated.',
  ]);

  final String message;
}
