import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _dataSource;
  PaymentRepositoryImpl(this._dataSource);

  @override
  Stream<List<PaymentEntity>> getPaymentsByLoan(String loanId) => _dataSource
      .getPaymentsByLoan(loanId)
      .map((list) => list.map((m) => m.toEntity()).toList());

  @override
  Stream<List<PaymentEntity>> getPaymentsByClient(String clientId) =>
      _dataSource
          .getPaymentsByClient(clientId)
          .map((list) => list.map((m) => m.toEntity()).toList());

  @override
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
  }) =>
      _dataSource.registerPayment(
        paymentId: paymentId,
        clientId: clientId,
        method: method,
        paidDate: paidDate,
        penaltyAmount: penaltyAmount,
        penaltyReason: penaltyReason,
        notes: notes,
        expectedDate: expectedDate,
        amount: amount,
        paymentNumber: paymentNumber,
      );

  @override
  Future<void> addPenalty({
    required String paymentId,
    required double penaltyAmount,
    required String penaltyReason,
  }) =>
      _dataSource.addPenalty(
        paymentId: paymentId,
        penaltyAmount: penaltyAmount,
        penaltyReason: penaltyReason,
      );
}
