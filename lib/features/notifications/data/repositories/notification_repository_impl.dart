import '../../domain/entities/client_notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;
  NotificationRepositoryImpl(this._dataSource);

  @override
  Stream<List<ClientNotificationEntity>> watchUnread(String clientId) =>
      _dataSource
          .watchUnread(clientId)
          .map((list) => list.map((m) => m.toEntity()).toList());

  @override
  Future<void> markAsRead(String clientId, String notificationId) =>
      _dataSource.markAsRead(clientId, notificationId);

  @override
  Future<void> createPaymentNotification({
    required String clientId,
    required String paymentId,
    required int paymentNumber,
    required double amount,
  }) =>
      _dataSource.createPaymentNotification(
        clientId: clientId,
        paymentId: paymentId,
        paymentNumber: paymentNumber,
        amount: amount,
      );
}
