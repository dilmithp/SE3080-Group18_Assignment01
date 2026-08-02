import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';

/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/app_user_dto.dart) convert Firestore documents to and
/// from this type; nothing outside data/ should know Firestore exists.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String phone;
  final UserRole role;
  final bool isVerified;
  final DateTime createdAt;

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    UserRole? role,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          phone == other.phone &&
          role == other.role &&
          isVerified == other.isVerified &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, email, phone, role, isVerified, createdAt);
}
