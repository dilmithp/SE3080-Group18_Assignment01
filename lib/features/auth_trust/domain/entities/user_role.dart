enum UserRole {
  elderly,
  volunteer,
  admin;

  String get label {
    switch (this) {
      case UserRole.elderly:
        return 'Elderly member';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
