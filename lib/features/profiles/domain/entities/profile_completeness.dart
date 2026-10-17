import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';

/// How fully a [UserProfile] is filled in, and which items are still missing.
///
/// Pure domain logic — no Firebase or Flutter imports. Every item carries the
/// same weight, so [percent] is simply the share of items completed. The
/// [missing] labels are shown verbatim to the user as next steps.
class ProfileCompleteness {
  const ProfileCompleteness._({
    required this.completedCount,
    required this.totalCount,
    required this.missing,
  });

  factory ProfileCompleteness.of(UserProfile profile) {
    final checks = <(String, bool)>[
      ('Add your name', profile.displayName.trim().isNotEmpty),
      ('Add a profile photo', profile.photoUrl != null),
      ('Write a short bio', profile.bio.trim().isNotEmpty),
      ('Set your locality', profile.locality.trim().isNotEmpty),
      (
        'Set your location on the map',
        profile.geoPoint.latitude != 0 || profile.geoPoint.longitude != 0,
      ),
      ('List languages you speak', profile.languagesSpoken.isNotEmpty),
      ('List skills you can offer', profile.skillsOffered.isNotEmpty),
      ('List the help you need', profile.helpNeeded.isNotEmpty),
      ('Add when you are available', profile.availabilityWindows.isNotEmpty),
      (
        'Add an emergency contact',
        profile.emergencyContactPhone?.trim().isNotEmpty ?? false,
      ),
    ];

    final done = checks.where((c) => c.$2).length;
    return ProfileCompleteness._(
      completedCount: done,
      totalCount: checks.length,
      missing: [
        for (final check in checks)
          if (!check.$2) check.$1,
      ],
    );
  }

  final int completedCount;
  final int totalCount;
  final List<String> missing;

  double get fraction => completedCount / totalCount;

  int get percent => (fraction * 100).round();

  bool get isComplete => missing.isEmpty;
}
