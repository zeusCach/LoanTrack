import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/client_notification_model.dart';

abstract class NotificationDataSource {
  Stream<List<ClientNotificationModel>> watchUnread(String clientId);
  Future<void> markAsRead(String clientId, String notificationId);
  Future<void> createPaymentNotification({
    required String clientId,
    required String paymentId,
    required int paymentNumber,
    required double amount,
  });
}

class NotificationDataSourceImpl implements NotificationDataSource {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  NotificationDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _col(String clientId) =>
      _firestore.collection('users').doc(clientId).collection('notifications');

  @override
  Stream<List<ClientNotificationModel>> watchUnread(String clientId) {
    return _col(clientId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ClientNotificationModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> markAsRead(String clientId, String notificationId) async {
    await _col(clientId).doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> createPaymentNotification({
    required String clientId,
    required String paymentId,
    required int paymentNumber,
    required double amount,
  }) async {
    final id = _uuid.v4();
    final model = ClientNotificationModel(
      id: id,
      clientId: clientId,
      title: 'Pago registrado',
      body: '✅ Tu cuota #$paymentNumber por \$${amount.toStringAsFixed(2)} fue registrada',
      paymentId: paymentId,
      paymentNumber: paymentNumber,
      amount: amount,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await _col(clientId).doc(id).set(model.toFirestore());
  }
}
