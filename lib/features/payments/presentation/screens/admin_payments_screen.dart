import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../clients/domain/entities/client_entity.dart';
import '../../../clients/presentation/providers/client_provider.dart';
import '../../../loans/presentation/providers/loan_provider.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/payment_provider.dart';
import 'register_payment_screen.dart';

/// Lista las cuotas con `status: pending` cuya fecha esperada es hoy o
/// anterior (atrasadas). Combina `adminLoansProvider` con
/// `loanPaymentsProvider` por cada préstamo activo.
class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(adminLoansProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pagos del día'),
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (loans) {
          final clientsById = <String, String>{
            for (final c in clientsAsync.value ?? const <ClientEntity>[])
              c.uid: c.name,
          };
          if (loans.isEmpty) {
            return const Center(
              child: Text(
                'No hay préstamos registrados',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          // Agregamos los pagos pendientes (vencen hoy o antes) de cada préstamo.
          final tiles = <_DuePaymentTile>[];
          var stillLoading = false;

          for (final loan in loans) {
            final paymentsAsync = ref.watch(loanPaymentsProvider(loan.id));
            paymentsAsync.when(
              loading: () => stillLoading = true,
              error: (_, __) {},
              data: (payments) {
                for (final p in payments) {
                  if (p.status != PaymentStatus.pending) continue;
                  if (p.expectedDate.isAfter(endOfToday)) continue;
                  tiles.add(_DuePaymentTile(
                    payment: p,
                    clientName: clientsById[p.clientId] ?? 'Cliente',
                    currency: currency,
                    dateFormat: dateFormat,
                  ));
                }
              },
            );
          }

          tiles.sort((a, b) => a.payment.expectedDate
              .compareTo(b.payment.expectedDate));

          if (tiles.isEmpty) {
            if (stillLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay pagos pendientes ni atrasados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => tiles[i],
          );
        },
      ),
    );
  }
}

class _DuePaymentTile extends StatelessWidget {
  final PaymentEntity payment;
  final String clientName;
  final NumberFormat currency;
  final DateFormat dateFormat;

  const _DuePaymentTile({
    required this.payment,
    required this.clientName,
    required this.currency,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final daysLate =
        startOfToday.difference(_dayOnly(payment.expectedDate)).inDays;
    final isOverdue = daysLate > 0;
    final color = isOverdue ? AppColors.danger : AppColors.warning;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => RegisterPaymentScreen(payment: payment),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    clientName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOverdue ? '$daysLate día(s) atraso' : 'Hoy',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cuota #${payment.paymentNumber}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(payment.amount),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Vence: ${dateFormat.format(payment.expectedDate)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
