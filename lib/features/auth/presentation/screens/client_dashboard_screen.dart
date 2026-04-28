import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../loans/domain/entities/loan_entity.dart';
import '../../../loans/presentation/providers/loan_provider.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/client_dashboard_provider.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final statsAsync = ref.watch(clientDashboardStatsProvider(user.uid));
    final loansAsync = ref.watch(clientLoansProvider(user.uid));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Mi panel · ${user.name}'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authRepositoryProvider).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientLoansProvider(user.uid));
          ref.invalidate(clientDashboardStatsProvider(user.uid));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        _StatCard('Préstamos activos', '${stats.activeLoans}',
                            Icons.account_balance_rounded, AppColors.primary),
                        const SizedBox(width: 12),
                        _StatCard('Cuotas pagadas', '${stats.paidInstallments}',
                            Icons.check_circle_rounded, AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatCard('Pendientes', '${stats.pendingInstallments}',
                            Icons.schedule_rounded, AppColors.warning),
                        const SizedBox(width: 12),
                        _StatCard('Atrasadas', '${stats.lateInstallments}',
                            Icons.warning_rounded, AppColors.danger),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo restante: ${currency.format(stats.remainingBalance)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: stats.progress),
                          const SizedBox(height: 4),
                          Text(
                            'Pagado ${currency.format(stats.totalPaid)} de ${currency.format(stats.totalDebt)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Estado de mis préstamos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              loansAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (loans) {
                  if (loans.isEmpty) {
                    return const Text('No tienes préstamos registrados.');
                  }
                  return Column(
                    children: loans
                        .map((loan) => _LoanStatusCard(loan: loan))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/client/payments'),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Historial pagos'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/client/history'),
                      icon: const Icon(Icons.track_changes_rounded),
                      label: const Text('Progreso'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _LoanStatusCard extends ConsumerWidget {
  final LoanEntity loan;

  const _LoanStatusCard({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(loanPaymentsProvider(loan.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: paymentsAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 8),
        error: (e, _) => Text('Error: $e'),
        data: (payments) {
          final paid = payments
              .where((p) => p.status != PaymentStatus.pending)
              .length;
          final late = payments.where((p) => p.status == PaymentStatus.late).length;
          final progress = payments.isEmpty ? 0.0 : (paid / payments.length);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Préstamo ${loan.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 6),
              Text('Cuotas pendientes: ${payments.length - paid} · Atrasadas: $late'),
            ],
          );
        },
      ),
    );
  }
}
