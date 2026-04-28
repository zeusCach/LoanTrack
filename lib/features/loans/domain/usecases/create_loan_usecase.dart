import '../entities/loan_entity.dart';
import '../repositories/loan_repository.dart';

class CreateLoanParams {
  final String clientId;
  final String adminId;
  final double totalAmount;
  final int totalPayments;
  final double interestRate;
  final String frequency;
  final DateTime startDate;

  const CreateLoanParams({
    required this.clientId,
    required this.adminId,
    required this.totalAmount,
    required this.totalPayments,
    required this.interestRate,
    required this.frequency,
    required this.startDate,
  });
}

class CreateLoanUseCase {
  final LoanRepository _repository;
  const CreateLoanUseCase(this._repository);

  Future<LoanEntity> call(CreateLoanParams params) => _repository.createLoan(
        clientId: params.clientId,
        adminId: params.adminId,
        totalAmount: params.totalAmount,
        totalPayments: params.totalPayments,
        interestRate: params.interestRate,
        frequency: params.frequency,
        startDate: params.startDate,
      );
}
