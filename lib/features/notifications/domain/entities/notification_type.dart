/// The kinds of in-app notification the platform can raise. Stored on the
/// Firestore document as its snake_case [value] rather than the Dart enum
/// name (see data/models/app_notification_dto.dart) so the stored string
/// stays stable even if this enum is ever reordered or renamed in Dart.
///
/// A new notification-worthy event is a new value here plus a switch arm
/// wherever the human-readable title/body get built — never a string
/// scattered through calling code.
enum NotificationType {
  sessionConfirmed('session_confirmed'),
  sessionCancelled('session_cancelled'),
  sessionCompleted('session_completed'),
  feedbackReceived('feedback_received'),
  verificationApproved('verification_approved'),
  verificationRejected('verification_rejected'),

  /// Fallback for a stored value this build doesn't recognise (an older or
  /// newer client wrote a type this enum doesn't have a case for) — never
  /// written by this app itself.
  other('other');

  const NotificationType(this.value);

  /// The exact string persisted on the `notifications/{id}` document.
  final String value;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.other,
    );
  }
}
