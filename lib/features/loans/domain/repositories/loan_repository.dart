import '../entities/loan_entity.dart';

abstract class LoanRepository {
  Stream<List<LoanEntity>> getLoansByClient(String clientId);
  Stream<List<LoanEntity>> getLoansByAdmin(String adminId);
  Future<LoanEntity> createLoan({
    required String clientId,
    required String adminId,
    required double totalAmount,
    required int totalPayments,
    required double interestRate,
    required String frequency,
    required DateTime startDate,
  });
  Future<void> updateLoanStatus(String loanId, String status);
}
