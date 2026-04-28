import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class RegisterPaymentParams {
  final String paymentId;
  final PaymentMethod method;
  final DateTime paidDate;
  final double penaltyAmount;
  final String penaltyReason;
  final String notes;
  final DateTime expectedDate;

  const RegisterPaymentParams({
    required this.paymentId,
    required this.method,
    required this.paidDate,
    required this.penaltyAmount,
    required this.penaltyReason,
    required this.notes,
    required this.expectedDate,
  });
}

class RegisterPaymentUseCase {
  final PaymentRepository _repository;
  const RegisterPaymentUseCase(this._repository);

  Future<void> call(RegisterPaymentParams params) =>
      _repository.registerPayment(
        paymentId: params.paymentId,
        method: params.method,
        paidDate: params.paidDate,
        penaltyAmount: params.penaltyAmount,
        penaltyReason: params.penaltyReason,
        notes: params.notes,
        expectedDate: params.expectedDate,
      );
}
