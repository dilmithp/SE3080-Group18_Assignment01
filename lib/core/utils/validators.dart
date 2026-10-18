/// Shared form-field validators for `TextFormField.validator` /
/// [AppTextField]. Each returns an error string or `null` if valid.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (!_phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String fieldName = 'This field'}) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters.';
    }
    return null;
  }

  /// Like [phone] but accepts a blank/null value (the field is optional).
  /// Only validates format when a non-empty value is provided.
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid phone number (e.g. +94 71 234 5678).';
    }
    return null;
  }

  /// Validates that [value] does not exceed [max] characters. Returns `null`
  /// when the value is blank — the caller is responsible for [required]
  /// validation if the field is mandatory. [message] lets a caller with a
  /// `BuildContext` supply a localized string (e.g. from AppLocalizations);
  /// without it, a plain English fallback is used.
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'This field',
    String Function(int max)? message,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > max) {
      return message?.call(max) ?? '$fieldName must be at most $max characters.';
    }
    return null;
  }

  /// Validates a comma-separated tag list:
  /// - At most [maxCount] tags (default 20).
  /// - Each individual tag at most [maxTagLength] characters (default 50).
  /// [tooManyMessage]/[tagTooLongMessage] let a caller supply localized
  /// strings; without them, a plain English fallback is used.
  static String? tagList(
    String? value, {
    int maxCount = 20,
    int maxTagLength = 50,
    String Function(int max)? tooManyMessage,
    String Function(int max)? tagTooLongMessage,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final tags = value
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tags.length > maxCount) {
      return tooManyMessage?.call(maxCount) ?? 'Add at most $maxCount tags.';
    }
    for (final tag in tags) {
      if (tag.length > maxTagLength) {
        return tagTooLongMessage?.call(maxTagLength) ??
            'Each tag must be at most $maxTagLength characters.';
      }
    }
    return null;
  }
}
