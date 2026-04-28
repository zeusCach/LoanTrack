import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../domain/entities/loan_entity.dart';
import '../providers/loan_provider.dart';

class ClientLoansStatusScreen extends ConsumerWidget {
  const ClientLoansStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final loansAsync = ref.watch(clientLoansProvider(user.uid));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado del préstamo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (loans) {
          if (loans.isEmpty) {
            return const Center(child: Text('No tienes préstamos activos.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _LoanProgressCard(loan: loans[i], currency: currency),
          );
        },
      ),
    );
  }
}

class _LoanProgressCard extends ConsumerWidget {
  final LoanEntity loan;
  final NumberFormat currency;

  const _LoanProgressCard({required this.loan, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(loanPaymentsProvider(loan.id));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (payments) {
          final paid = payments
              .where((p) => p.status != PaymentStatus.pending)
              .length;
          final pending = payments.length - paid;
          final late = payments.where((p) => p.status == PaymentStatus.late).length;
          final progress = payments.isEmpty ? 0.0 : paid / payments.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Préstamo #${loan.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Monto total: ${currency.format(loan.totalAmount)}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text('Cuotas pagadas: $paid/${payments.length}'),
              Text('Cuotas faltantes: $pending'),
              Text(
                'Pagos atrasados: $late',
                style: TextStyle(
                    color: late > 0 ? AppColors.danger : AppColors.textSecondary,
                    fontWeight: late > 0 ? FontWeight.w600 : FontWeight.normal),
              ),
            ],
          );
        },
      ),
    );
  }
}
