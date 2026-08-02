/// Pure domain entity — zero `package:firebase_*` imports. Domain code must
/// never import `cloud_firestore`'s `GeoPoint`; this hand-rolled type exists
/// so the profiles domain layer stays Firestore-agnostic. Data-layer DTOs
/// (see data/models/user_profile_dto.dart) flatten this to `latitude`/
/// `longitude` fields and convert to/from Firestore's `GeoPoint` at the
/// data-source boundary only.
class GeoCoordinates {
  const GeoCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  GeoCoordinates copyWith({
    double? latitude,
    double? longitude,
  }) {
    return GeoCoordinates(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinates &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
