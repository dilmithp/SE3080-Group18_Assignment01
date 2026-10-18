/// Lifecycle of an [SosAlert]. Stored on the Firestore document as its
/// snake_case [value] — see data/models/sos_alert_dto.dart.
enum SosAlertStatus {
  active('active'),
  resolved('resolved');

  const SosAlertStatus(this.value);

  final String value;

  static SosAlertStatus fromValue(String value) {
    return SosAlertStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SosAlertStatus.active,
    );
  }
}
