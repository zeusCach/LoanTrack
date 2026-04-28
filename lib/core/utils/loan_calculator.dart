import '../../features/payments/data/models/payment_model.dart';
import '../../features/payments/domain/entities/payment_entity.dart';
import '../../features/loans/domain/entities/loan_entity.dart';

class LoanCalculator {
  /// Genera todas las cuotas del préstamo automáticamente
  static List<PaymentModel> generatePayments({
    required String loanId,
    required String clientId,
    required String adminId,
    required double paymentAmount,
    required int totalPayments,
    required LoanFrequency frequency,
    required DateTime startDate,
  }) {
    final payments = <PaymentModel>[];

    for (int i = 0; i < totalPayments; i++) {
      final expectedDate = _calculateDate(startDate, frequency, i + 1);
      payments.add(PaymentModel(
        id: '',
        loanId: loanId,
        clientId: clientId,
        adminId: adminId,
        amount: paymentAmount,
        expectedDate: expectedDate,
        paidDate: null,
        status: PaymentStatus.pending,
        method: null,
        penaltyAmount: 0,
        penaltyReason: '',
        paymentNumber: i + 1,
        notes: '',
        createdAt: DateTime.now(),
      ));
    }

    return payments;
  }

  static DateTime _calculateDate(
    DateTime start,
    LoanFrequency frequency,
    int paymentNumber,
  ) {
    switch (frequency) {
      case LoanFrequency.weekly:
        return start.add(Duration(days: 7 * paymentNumber));
      case LoanFrequency.biweekly:
        return start.add(Duration(days: 14 * paymentNumber));
      case LoanFrequency.monthly:
        return DateTime(
          start.year,
          start.month + paymentNumber,
          start.day,
        );
    }
  }

  /// Calcula fecha fin del préstamo
  static DateTime calculateEndDate({
    required DateTime startDate,
    required LoanFrequency frequency,
    required int totalPayments,
  }) {
    return _calculateDate(startDate, frequency, totalPayments);
  }

  /// Calcula monto por cuota con interés
  static double calculatePaymentAmount({
    required double totalAmount,
    required double interestRate,
    required int totalPayments,
  }) {
    final totalWithInterest = totalAmount * (1 + interestRate / 100);
    return double.parse(
      (totalWithInterest / totalPayments).toStringAsFixed(2),
    );
  }
}
