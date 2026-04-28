import '../entities/loan_entity.dart';
import '../repositories/loan_repository.dart';

class GetLoansByClientUseCase {
  final LoanRepository _repository;
  const GetLoansByClientUseCase(this._repository);

  Stream<List<LoanEntity>> call(String clientId) =>
      _repository.getLoansByClient(clientId);
}

class GetLoansByAdminUseCase {
  final LoanRepository _repository;
  const GetLoansByAdminUseCase(this._repository);

  Stream<List<LoanEntity>> call(String adminId) =>
      _repository.getLoansByAdmin(adminId);
}
