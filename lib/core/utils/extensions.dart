import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String toDisplayDate() => DateFormat('d MMM y').format(this);

  String toDisplayTime() => DateFormat('h:mm a').format(this);

  String toDisplayDateTime() => DateFormat('d MMM y, h:mm a').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension StringCasing on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
}
