import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String adminId;
  final DateTime createdAt;
  final bool isActive;

  const ClientEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.adminId,
    required this.createdAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [uid, email];
}
