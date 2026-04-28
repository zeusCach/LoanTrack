import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client_notification_entity.dart';

class ClientNotificationModel {
  final String id;
  final String clientId;
  final String title;
  final String body;
  final String paymentId;
  final int paymentNumber;
  final double amount;
  final bool isRead;
  final DateTime createdAt;

  const ClientNotificationModel({
    required this.id,
    required this.clientId,
    required this.title,
    required this.body,
    required this.paymentId,
    required this.paymentNumber,
    required this.amount,
    required this.isRead,
    required this.createdAt,
  });

  factory ClientNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientNotificationModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      paymentId: data['paymentId'] ?? '',
      paymentNumber: data['paymentNumber'] ?? 0,
      amount: (data['amount'] as num? ?? 0).toDouble(),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clientId': clientId,
        'title': title,
        'body': body,
        'paymentId': paymentId,
        'paymentNumber': paymentNumber,
        'amount': amount,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ClientNotificationEntity toEntity() => ClientNotificationEntity(
        id: id,
        clientId: clientId,
        title: title,
        body: body,
        paymentId: paymentId,
        paymentNumber: paymentNumber,
        amount: amount,
        isRead: isRead,
        createdAt: createdAt,
      );
}
