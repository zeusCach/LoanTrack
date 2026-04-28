import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Stream<List<PaymentEntity>> getPaymentsByLoan(String loanId);
  Stream<List<PaymentEntity>> getPaymentsByClient(String clientId);
  Future<void> registerPayment({
    required String paymentId,
    required String clientId,
    required PaymentMethod method,
    required DateTime paidDate,
    required double penaltyAmount,
    required String penaltyReason,
    required String notes,
    required DateTime expectedDate,
    required double amount,
    required int paymentNumber,
  });
  Future<void> addPenalty({
    required String paymentId,
    required double penaltyAmount,
    required String penaltyReason,
  });
}
