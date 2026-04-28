import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loan_repository.dart';
import '../datasources/loan_remote_datasource.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoanRemoteDataSource _dataSource;
  LoanRepositoryImpl(this._dataSource);

  @override
  Stream<List<LoanEntity>> getLoansByClient(String clientId) => _dataSource
      .getLoansByClient(clientId)
      .map((list) => list.map((m) => m.toEntity()).toList());

  @override
  Stream<List<LoanEntity>> getLoansByAdmin(String adminId) => _dataSource
      .getLoansByAdmin(adminId)
      .map((list) => list.map((m) => m.toEntity()).toList());

  @override
  Future<LoanEntity> createLoan({
    required String clientId,
    required String adminId,
    required double totalAmount,
    required int totalPayments,
    required double interestRate,
    required String frequency,
    required DateTime startDate,
  }) async {
    final model = await _dataSource.createLoan(
      clientId: clientId,
      adminId: adminId,
      totalAmount: totalAmount,
      totalPayments: totalPayments,
      interestRate: interestRate,
      frequency: frequency,
      startDate: startDate,
    );
    return model.toEntity();
  }

  @override
  Future<void> updateLoanStatus(String loanId, String status) =>
      _dataSource.updateLoanStatus(loanId, status);
}
