import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class GetPaymentsByLoanUseCase {
  final PaymentRepository _repository;
  const GetPaymentsByLoanUseCase(this._repository);

  Stream<List<PaymentEntity>> call(String loanId) =>
      _repository.getPaymentsByLoan(loanId);
}

class GetPaymentsByClientUseCase {
  final PaymentRepository _repository;
  const GetPaymentsByClientUseCase(this._repository);

  Stream<List<PaymentEntity>> call(String clientId) =>
      _repository.getPaymentsByClient(clientId);
}