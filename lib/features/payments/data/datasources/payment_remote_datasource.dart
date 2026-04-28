import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/payment_entity.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Stream<List<PaymentModel>> getPaymentsByLoan(String loanId);
  Stream<List<PaymentModel>> getPaymentsByClient(String clientId);
  Future<void> registerPayment({
    required String paymentId,
    required PaymentMethod method,
    required DateTime paidDate,
    required double penaltyAmount,
    required String penaltyReason,
    required String notes,
    required DateTime expectedDate,
  });
  Future<void> addPenalty({
    required String paymentId,
    required double penaltyAmount,
    required String penaltyReason,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;

  PaymentRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<PaymentModel>> getPaymentsByLoan(String loanId) {
    return _firestore
        .collection('payments')
        .where('loanId', isEqualTo: loanId)
        .orderBy('paymentNumber')
        .snapshots()
        .map((s) => s.docs.map((d) => PaymentModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<PaymentModel>> getPaymentsByClient(String clientId) {
    return _firestore
        .collection('payments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('expectedDate')
        .snapshots()
        .map((s) => s.docs.map((d) => PaymentModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> registerPayment({
    required String paymentId,
    required PaymentMethod method,
    required DateTime paidDate,
    required double penaltyAmount,
    required String penaltyReason,
    required String notes,
    required DateTime expectedDate,
  }) async {
    try {
      // Determina si es adelantado o atrasado
      final status = paidDate.isBefore(expectedDate)
          ? PaymentStatus.early
          : paidDate.isAfter(expectedDate)
              ? PaymentStatus.late
              : PaymentStatus.paid;

      await _firestore.collection('payments').doc(paymentId).update({
        'paidDate': Timestamp.fromDate(paidDate),
        'status': status.name,
        'method': method.name,
        'penaltyAmount': penaltyAmount,
        'penaltyReason': penaltyReason,
        'notes': notes,
      });

      // Verifica si todos los pagos del préstamo están completos
      await _checkAndCompleteLoan(paymentId);
    } catch (e) {
      throw ServerException('Error al registrar pago: $e');
    }
  }

  @override
  Future<void> addPenalty({
    required String paymentId,
    required double penaltyAmount,
    required String penaltyReason,
  }) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'penaltyAmount': penaltyAmount,
      'penaltyReason': penaltyReason,
      'status': PaymentStatus.late.name,
    });
  }

  Future<void> _checkAndCompleteLoan(String paymentId) async {
    final payDoc = await _firestore.collection('payments').doc(paymentId).get();
    final loanId = payDoc.data()?['loanId'] as String?;
    if (loanId == null) return;

    final allPayments = await _firestore
        .collection('payments')
        .where('loanId', isEqualTo: loanId)
        .get();

    final allPaid = allPayments.docs.every((doc) {
      final status = doc.data()['status'] as String;
      return status == 'paid' || status == 'early' || status == 'late';
    });

    if (allPaid) {
      await _firestore
          .collection('loans')
          .doc(loanId)
          .update({'status': 'completed'});
    }
  }
}
