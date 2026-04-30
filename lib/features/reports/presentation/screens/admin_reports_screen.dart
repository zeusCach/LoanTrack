import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../clients/domain/entities/client_entity.dart';
import '../../../clients/presentation/providers/client_provider.dart';
import '../../../loans/domain/entities/loan_entity.dart';
import '../../../loans/presentation/providers/loan_provider.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';

/// Resumen de actividad del admin: monto prestado, cobrado, pendiente y mora
/// vigente. Top 5 deudores por saldo pendiente. Datos derivados de los
/// streams ya existentes (`adminLoansProvider` + `loanPaymentsProvider`),
/// sin nuevas queries a Firestore.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(adminLoansProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Reportes'),
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (loans) {
          final clientsById = <String, String>{
            for (final c in clientsAsync.value ?? const <ClientEntity>[])
              c.uid: c.name,
          };

          // Agregamos pagos de todos los préstamos via loanPaymentsProvider.
          var stillLoading = false;
          double totalLent = 0;
          double totalCollected = 0;
          double totalPending = 0;
          double totalOverdue = 0;
          int activeCount = 0;
          int defaultedCount = 0;
          int completedCount = 0;
          int paidInstallments = 0;
          int overdueInstallments = 0;

          // saldo pendiente por cliente (cuotas pendientes + atrasadas)
          final pendingByClient = <String, double>{};
          final today = DateTime.now();
          final startOfToday = DateTime(today.year, today.month, today.day);

          for (final loan in loans) {
            totalLent += loan.totalAmount;
            switch (loan.status) {
              case LoanStatus.active:
                activeCount++;
                break;
              case LoanStatus.defaulted:
                defaultedCount++;
                break;
              case LoanStatus.completed:
                completedCount++;
                break;
            }

            final paymentsAsync = ref.watch(loanPaymentsProvider(loan.id));
            paymentsAsync.when(
              loading: () => stillLoading = true,
              error: (_, __) {},
              data: (payments) {
                for (final p in payments) {
                  switch (p.status) {
                    case PaymentStatus.paid:
                    case PaymentStatus.early:
                      totalCollected += p.amount + p.penaltyAmount;
                      paidInstallments++;
                      break;
                    case PaymentStatus.late:
                      totalCollected += p.amount + p.penaltyAmount;
                      paidInstallments++;
                      break;
                    case PaymentStatus.pending:
                      totalPending += p.amount;
                      pendingByClient.update(
                        p.clientId,
                        (v) => v + p.amount,
                        ifAbsent: () => p.amount,
                      );
                      final expectedDay = DateTime(
                        p.expectedDate.year,
                        p.expectedDate.month,
                        p.expectedDate.day,
                      );
                      if (expectedDay.isBefore(startOfToday)) {
                        totalOverdue += p.amount;
                        overdueInstallments++;
                      }
                      break;
                  }
                }
              },
            );
          }

          final topDebtors = pendingByClient.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top5 = topDebtors.take(5).toList();

          if (stillLoading && loans.isNotEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumen financiero
              const _SectionTitle('Resumen financiero'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatCard(
                    label: 'Prestado',
                    value: currency.format(totalLent),
                    color: AppColors.primary,
                    icon: Icons.upload_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Cobrado',
                    value: currency.format(totalCollected),
                    color: AppColors.success,
                    icon: Icons.download_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: 'Por cobrar',
                    value: currency.format(totalPending),
                    color: AppColors.warning,
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'En atraso',
                    value: currency.format(totalOverdue),
                    color: AppColors.danger,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const _SectionTitle('Préstamos por estado'),
              const SizedBox(height: 8),
              _StatusBreakdown(
                active: activeCount,
                defaulted: defaultedCount,
                completed: completedCount,
              ),

              const SizedBox(height: 24),
              const _SectionTitle('Cuotas'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatCard(
                    label: 'Pagadas',
                    value: '$paidInstallments',
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Atrasadas',
                    value: '$overdueInstallments',
                    color: AppColors.danger,
                    icon: Icons.error_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const _SectionTitle('Top deudores'),
              const SizedBox(height: 8),
              if (top5.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay saldos pendientes.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < top5.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.danger.withValues(alpha: 0.1),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            clientsById[top5[i].key] ?? 'Cliente',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            currency.format(top5[i].value),
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final int active;
  final int defaulted;
  final int completed;

  const _StatusBreakdown({
    required this.active,
    required this.defaulted,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final total = active + defaulted + completed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: 'Activos',
            count: active,
            total: total,
            color: AppColors.success,
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'En mora',
            count: defaulted,
            total: total,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'Completados',
            count: completed,
            total: total,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              '$count${total > 0 ? ' (${(pct * 100).toStringAsFixed(0)}%)' : ''}',
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
