import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/payment_provider.dart';

class ClientPaymentsScreen extends ConsumerWidget {
  const ClientPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final paymentsAsync = ref.watch(clientPaymentsProvider(user.uid));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de pagos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No hay cuotas registradas.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final payment = payments[i];
              final color = _statusColor(payment.status);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.hardEdge,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: color),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_statusIcon(payment.status),
                                  color: color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text('Cuota #${payment.paymentNumber}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        _StatusChip(status: payment.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(currency.format(payment.amount),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (payment.penaltyAmount > 0)
                      Text(
                        '+ ${currency.format(payment.penaltyAmount)} sanción',
                        style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Vence: ${dateFormat.format(payment.expectedDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (payment.paidDate != null)
                      Text(
                        'Pagado: ${dateFormat.format(payment.paidDate!)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.success),
                      ),
                    if (payment.method != null)
                      Text(
                        payment.method == PaymentMethod.cash
                            ? 'Método: Efectivo'
                            : 'Método: Transferencia',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    if (payment.penaltyReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Motivo: ${payment.penaltyReason}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.danger),
                        ),
                      ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PaymentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _statusColor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
    case PaymentStatus.early:
      return AppColors.success;
    case PaymentStatus.late:
      return AppColors.danger;
    case PaymentStatus.pending:
      return AppColors.warning;
  }
}

IconData _statusIcon(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return Icons.check_circle_rounded;
    case PaymentStatus.early:
      return Icons.arrow_circle_up_rounded;
    case PaymentStatus.late:
      return Icons.warning_rounded;
    case PaymentStatus.pending:
      return Icons.radio_button_unchecked;
  }
}

String _statusLabel(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return 'Pagado';
    case PaymentStatus.early:
      return 'Adelantado';
    case PaymentStatus.late:
      return 'Atrasado';
    case PaymentStatus.pending:
      return 'Pendiente';
  }
}
