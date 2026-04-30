import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../../payments/presentation/screens/register_payment_screen.dart';
import '../../../payments/presentation/screens/add_penalty_screen.dart';
import '../../domain/entities/loan_entity.dart';

class LoanDetailScreen extends ConsumerWidget {
  final LoanEntity loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(loanPaymentsProvider(loan.id));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Préstamo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (payments) {
          final paid = payments
              .where((p) =>
                  p.isPaid ||
                  p.status == PaymentStatus.early ||
                  p.status == PaymentStatus.late)
              .length;
          final pending =
              payments.where((p) => p.status == PaymentStatus.pending).length;

          return Column(
            children: [
              // Header resumen
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppColors.primary,
                child: Column(
                  children: [
                    Text(
                      currency.format(loan.totalAmount),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HeaderStat(
                            label: 'Pagadas',
                            value: '$paid',
                            color: Colors.greenAccent),
                        _HeaderStat(
                            label: 'Pendientes',
                            value: '$pending',
                            color: Colors.orangeAccent),
                        _HeaderStat(
                            label: 'Total',
                            value: '${loan.totalPayments}',
                            color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: loan.totalPayments > 0
                          ? paid / loan.totalPayments
                          : 0,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.greenAccent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((paid / loan.totalPayments) * 100).toStringAsFixed(0)}% completado',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Lista de cuotas
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final payment = payments[i];
                    return _PaymentTile(
                      payment: payment,
                      currency: currency,
                      dateFormat: dateFormat,
                      onRegister: payment.status == PaymentStatus.pending
                          ? () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    RegisterPaymentScreen(payment: payment),
                              )
                          : null,
                      onPenalty: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddPenaltyScreen(payment: payment),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentEntity payment;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final VoidCallback? onRegister;
  final VoidCallback onPenalty;

  const _PaymentTile({
    required this.payment,
    required this.currency,
    required this.dateFormat,
    required this.onRegister,
    required this.onPenalty,
  });

  Color get _statusColor {
    switch (payment.status) {
      case PaymentStatus.paid:
      case PaymentStatus.early:
        return AppColors.success;
      case PaymentStatus.late:
        return AppColors.danger;
      case PaymentStatus.pending:
        return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (payment.status) {
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

  IconData get _statusIcon {
    switch (payment.status) {
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

  @override
  Widget build(BuildContext context) {
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
            Container(width: 4, color: _statusColor),
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
                      color: _statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon, color: _statusColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Cuota #${payment.paymentNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currency.format(payment.amount),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  if (payment.hasPenalty)
                    Text(
                      '+ ${currency.format(payment.penaltyAmount)} sanción',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Vence: ${dateFormat.format(payment.expectedDate)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (payment.paidDate != null)
                    Text(
                      'Pagó: ${dateFormat.format(payment.paidDate!)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.success),
                    ),
                ],
              ),
            ],
          ),
          if (payment.method != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                payment.method == PaymentMethod.cash
                    ? '💵 Efectivo'
                    : '🏦 Transferencia',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          if (payment.penaltyReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Motivo sanción: ${payment.penaltyReason}',
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          // Acciones
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (onRegister != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRegister,
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Registrar pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  if (onRegister != null) const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onPenalty,
                    icon: const Icon(Icons.warning_amber, size: 16),
                    label: const Text('Sanción'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
  }
}
