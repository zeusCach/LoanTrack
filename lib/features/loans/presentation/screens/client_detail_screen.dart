import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loantrack/features/loans/presentation/screens/loan_detail_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../clients/domain/entities/client_entity.dart';
import '../providers/loan_provider.dart';
import '../../domain/entities/loan_entity.dart';
import 'create_loan_screen.dart';

class ClientDetailScreen extends ConsumerWidget {
  final ClientEntity client;

  const ClientDetailScreen({super.key, required this.client});

  Color _statusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return AppColors.success;
      case LoanStatus.completed:
        return AppColors.primary;
      case LoanStatus.defaulted:
        return AppColors.danger;
    }
  }

  String _statusLabel(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return 'Activo';
      case LoanStatus.completed:
        return 'Completado';
      case LoanStatus.defaulted:
        return 'En mora';
    }
  }

  String _frequencyLabel(LoanFrequency f) {
    switch (f) {
      case LoanFrequency.weekly:
        return 'Semanal';
      case LoanFrequency.biweekly:
        return 'Quincenal';
      case LoanFrequency.monthly:
        return 'Mensual';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(clientLoansProvider(client.uid));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateLoanScreen(
              clientId: client.uid,
              clientName: client.name,
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Nuevo préstamo', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info cliente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      client.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(client.email,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      Text(client.phone,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Préstamos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            loansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (loans) {
                if (loans.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Sin préstamos aún',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final loan = loans[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoanDetailScreen(loan: loans[i]),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currency.format(loan.totalAmount),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(loan.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(loan.status),
                                    style: TextStyle(
                                      color: _statusColor(loan.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${loan.totalPayments} cuotas de ${currency.format(loan.paymentAmount)} — ${_frequencyLabel(loan.frequency)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.date_range,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${dateFormat.format(loan.startDate)} → ${dateFormat.format(loan.endDate)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
