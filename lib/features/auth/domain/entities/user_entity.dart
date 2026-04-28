import 'package:equatable/equatable.dart';

enum UserRole { admin, client }

class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? adminId;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.adminId,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [uid, email, role];
}
