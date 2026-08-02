/// Pure domain entity — zero `package:firebase_*` imports.
///
/// Represents a single recurring slot in a volunteer/elder's weekly
/// availability (e.g. dayOfWeek: "Monday", startTime: "09:00",
/// endTime: "12:00"). Times are stored as plain `HH:mm` strings rather than
/// [DateTime] since they describe a recurring time-of-day, not a fixed date.
class AvailabilityWindow {
  const AvailabilityWindow({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final String dayOfWeek;
  final String startTime;
  final String endTime;

  AvailabilityWindow copyWith({
    String? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return AvailabilityWindow(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityWindow &&
          runtimeType == other.runtimeType &&
          dayOfWeek == other.dayOfWeek &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(dayOfWeek, startTime, endTime);
}
