import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loantrack/features/loans/domain/entities/loan_entity.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/loan_calculator.dart';
import '../models/loan_model.dart';

abstract class LoanRemoteDataSource {
  Stream<List<LoanModel>> getLoansByClient(String clientId);
  Stream<List<LoanModel>> getLoansByAdmin(String adminId);
  Future<LoanModel> createLoan({
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

class LoanRemoteDataSourceImpl implements LoanRemoteDataSource {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  LoanRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<LoanModel>> getLoansByClient(String clientId) {
    return _firestore
        .collection('loans')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((s) => s.docs.map((d) => LoanModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<LoanModel>> getLoansByAdmin(String adminId) {
    return _firestore
        .collection('loans')
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((s) => s.docs.map((d) => LoanModel.fromFirestore(d)).toList());
  }

  @override
  Future<LoanModel> createLoan({
    required String clientId,
    required String adminId,
    required double totalAmount,
    required int totalPayments,
    required double interestRate,
    required String frequency,
    required DateTime startDate,
  }) async {
    try {
      final freq = LoanModel.frequencyFromString(frequency);
      final paymentAmount = LoanCalculator.calculatePaymentAmount(
        totalAmount: totalAmount,
        interestRate: interestRate,
        totalPayments: totalPayments,
      );
      final endDate = LoanCalculator.calculateEndDate(
        startDate: startDate,
        frequency: freq,
        totalPayments: totalPayments,
      );

      final loanId = _uuid.v4();
      final loan = LoanModel(
        id: loanId,
        clientId: clientId,
        adminId: adminId,
        totalAmount: totalAmount,
        totalPayments: totalPayments,
        paymentAmount: paymentAmount,
        frequency: freq,
        startDate: startDate,
        endDate: endDate,
        status: LoanStatus.active,
        interestRate: interestRate,
        createdAt: DateTime.now(),
      );

      // Batch write: préstamo + todas las cuotas
      final batch = _firestore.batch();

      final loanRef = _firestore.collection('loans').doc(loanId);
      batch.set(loanRef, loan.toFirestore());

      // Genera cuotas automáticamente
      final payments = LoanCalculator.generatePayments(
        loanId: loanId,
        clientId: clientId,
        adminId: adminId,
        paymentAmount: paymentAmount,
        totalPayments: totalPayments,
        frequency: freq,
        startDate: startDate,
      );

      for (final payment in payments) {
        final payRef = _firestore.collection('payments').doc(_uuid.v4());
        batch.set(payRef, payment.toFirestore());
      }

      await batch.commit();
      return loan;
    } catch (e) {
      throw ServerException('Error al crear préstamo: $e');
    }
  }

  @override
  Future<void> updateLoanStatus(String loanId, String status) async {
    await _firestore.collection('loans').doc(loanId).update({'status': status});
  }
}
