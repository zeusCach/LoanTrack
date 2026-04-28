import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../loans/domain/entities/loan_entity.dart';
import '../../../loans/presentation/providers/loan_provider.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';

class ClientDashboardStats {
  final int totalLoans;
  final int activeLoans;
  final int paidInstallments;
  final int pendingInstallments;
  final int lateInstallments;
  final double totalDebt;
  final double totalPaid;
  final double remainingBalance;

  const ClientDashboardStats({
    required this.totalLoans,
    required this.activeLoans,
    required this.paidInstallments,
    required this.pendingInstallments,
    required this.lateInstallments,
    required this.totalDebt,
    required this.totalPaid,
    required this.remainingBalance,
  });

  double get progress =>
      totalDebt == 0 ? 0 : (totalPaid / totalDebt).clamp(0, 1).toDouble();
}

final clientDashboardStatsProvider =
    Provider.family<AsyncValue<ClientDashboardStats>, String>((ref, clientId) {
  final loansAsync = ref.watch(clientLoansProvider(clientId));
  final paymentsAsync = ref.watch(clientPaymentsProvider(clientId));

  if (loansAsync.isLoading || paymentsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (loansAsync.hasError) {
    return AsyncValue.error(loansAsync.error!, loansAsync.stackTrace!);
  }

  if (paymentsAsync.hasError) {
    return AsyncValue.error(paymentsAsync.error!, paymentsAsync.stackTrace!);
  }

  final loans = loansAsync.value ?? const <LoanEntity>[];
  final payments = paymentsAsync.value ?? const <PaymentEntity>[];

  return AsyncValue.data(_buildStats(loans, payments));
});

ClientDashboardStats _buildStats(
  List<LoanEntity> loans,
  List<PaymentEntity> payments,
) {
  final paidStatuses = {
    PaymentStatus.paid,
    PaymentStatus.early,
    PaymentStatus.late,
  };
  final activeLoans = loans.where((loan) => loan.status == LoanStatus.active).length;
  final paidInstallments =
      payments.where((payment) => paidStatuses.contains(payment.status)).length;
  final pendingInstallments =
      payments.where((payment) => payment.status == PaymentStatus.pending).length;
  final lateInstallments =
      payments.where((payment) => payment.status == PaymentStatus.late).length;

  final totalDebt =
      loans.fold<double>(0, (sum, loan) => sum + (loan.paymentAmount * loan.totalPayments));
  final totalPaid = payments
      .where((payment) => paidStatuses.contains(payment.status))
      .fold<double>(0, (sum, payment) => sum + payment.amount + payment.penaltyAmount);

  return ClientDashboardStats(
    totalLoans: loans.length,
    activeLoans: activeLoans,
    paidInstallments: paidInstallments,
    pendingInstallments: pendingInstallments,
    lateInstallments: lateInstallments,
    totalDebt: totalDebt,
    totalPaid: totalPaid,
    remainingBalance:
        (totalDebt - totalPaid).clamp(0, double.infinity).toDouble(),
  );
}
