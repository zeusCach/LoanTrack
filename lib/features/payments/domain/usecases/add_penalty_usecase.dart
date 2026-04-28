import '../repositories/payment_repository.dart';

class AddPenaltyParams {
  final String paymentId;
  final double penaltyAmount;
  final String penaltyReason;
  final int paymentNumber;

  const AddPenaltyParams({
    required this.paymentId,
    required this.penaltyAmount,
    required this.penaltyReason,
    required this.paymentNumber,
  });
}

class AddPenaltyUseCase {
  final PaymentRepository _repository;
  const AddPenaltyUseCase(this._repository);

  Future<void> call(AddPenaltyParams params) => _repository.addPenalty(
        paymentId: params.paymentId,
        penaltyAmount: params.penaltyAmount,
        penaltyReason: params.penaltyReason,
      );
}
