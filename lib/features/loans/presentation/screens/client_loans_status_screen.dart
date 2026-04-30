import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';

class ClientLoansStatusScreen extends ConsumerWidget {
  const ClientLoansStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final paymentsAsync = ref.watch(clientPaymentsProvider(user.uid));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(
              child: Text('Sin movimientos registrados'),
            );
          }
          // Orden cronológico ascendente (más antiguo arriba).
          final sorted = [...payments]
            ..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: sorted.length,
            itemBuilder: (_, i) {
              return _TimelineEntry(
                payment: sorted[i],
                currency: currency,
                dateFormat: dateFormat,
                isFirst: i == 0,
                isLast: i == sorted.length - 1,
              );
            },
          );
        },
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final PaymentEntity payment;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntry({
    required this.payment,
    required this.currency,
    required this.dateFormat,
    required this.isFirst,
    required this.isLast,
  });

  Color get _color {
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

  IconData get _icon {
    switch (payment.status) {
      case PaymentStatus.paid:
        return Icons.check_rounded;
      case PaymentStatus.early:
        return Icons.arrow_upward_rounded;
      case PaymentStatus.late:
        return Icons.priority_high_rounded;
      case PaymentStatus.pending:
        return Icons.schedule_rounded;
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

  @override
  Widget build(BuildContext context) {
    final dateToShow = payment.paidDate ?? payment.expectedDate;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Columna del timeline (línea + círculo de estado)
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(_icon, color: Colors.white, size: 16),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card de la cuota
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuota #${payment.paymentNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(dateToShow),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: _color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currency.format(payment.amount),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (payment.penaltyAmount > 0)
                          Text(
                            '+ ${currency.format(payment.penaltyAmount)} sanción',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
