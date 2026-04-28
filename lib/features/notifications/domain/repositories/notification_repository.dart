import '../entities/client_notification_entity.dart';

abstract class NotificationRepository {
  Stream<List<ClientNotificationEntity>> watchUnread(String clientId);
  Future<void> markAsRead(String clientId, String notificationId);
  Future<void> createPaymentNotification({
    required String clientId,
    required String paymentId,
    required int paymentNumber,
    required double amount,
  });
}
