import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client_entity.dart';

class ClientModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String adminId;
  final DateTime createdAt;
  final bool isActive;

  const ClientModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.adminId,
    required this.createdAt,
    this.isActive = true,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      adminId: data['adminId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convierte a entidad del dominio
  ClientEntity toEntity() {
    return ClientEntity(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      adminId: adminId,
      createdAt: createdAt,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'client',
      'adminId': adminId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
