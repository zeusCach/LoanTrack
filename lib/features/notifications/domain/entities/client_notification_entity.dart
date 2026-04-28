class ClientNotificationEntity {
  final String id;
  final String clientId;
  final String title;
  final String body;
  final String paymentId;
  final int paymentNumber;
  final double amount;
  final bool isRead;
  final DateTime createdAt;

  const ClientNotificationEntity({
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
}
