import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../clients/domain/entities/client_entity.dart';
import '../../../clients/presentation/providers/client_provider.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../domain/entities/loan_entity.dart';
import '../providers/loan_provider.dart';
import 'loan_detail_screen.dart';

class AdminLoansScreen extends ConsumerWidget {
  const AdminLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(adminLoansProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Préstamos'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'En mora'),
              Tab(text: 'Completados'),
            ],
          ),
        ),
        body: loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (loans) {
            final clientsById = <String, String>{
              for (final c in clientsAsync.value ?? const <ClientEntity>[])
                c.uid: c.name,
            };
            final active =
                loans.where((l) => l.status == LoanStatus.active).toList();
            final defaulted =
                loans.where((l) => l.status == LoanStatus.defaulted).toList();
            final completed =
                loans.where((l) => l.status == LoanStatus.completed).toList();

            return TabBarView(
              children: [
                _LoansList(
                  loans: active,
                  clientsById: clientsById,
                  currency: currency,
                  dateFormat: dateFormat,
                  emptyText: 'Sin préstamos activos',
                ),
                _LoansList(
                  loans: defaulted,
                  clientsById: clientsById,
                  currency: currency,
                  dateFormat: dateFormat,
                  emptyText: 'Sin préstamos en mora',
                ),
                _LoansList(
                  loans: completed,
                  clientsById: clientsById,
                  currency: currency,
                  dateFormat: dateFormat,
                  emptyText: 'Sin préstamos completados',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoansList extends StatelessWidget {
  final List<LoanEntity> loans;
  final Map<String, String> clientsById;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final String emptyText;

  const _LoansList({
    required this.loans,
    required this.clientsById,
    required this.currency,
    required this.dateFormat,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final loan = loans[i];
        return _LoanCard(
          loan: loan,
          clientName: clientsById[loan.clientId] ?? 'Cliente',
          currency: currency,
          dateFormat: dateFormat,
        );
      },
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final LoanEntity loan;
  final String clientName;
  final NumberFormat currency;
  final DateFormat dateFormat;

  const _LoanCard({
    required this.loan,
    required this.clientName,
    required this.currency,
    required this.dateFormat,
  });

  Color get _statusColor {
    switch (loan.status) {
      case LoanStatus.active:
        return AppColors.success;
      case LoanStatus.defaulted:
        return AppColors.danger;
      case LoanStatus.completed:
        return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (loan.status) {
      case LoanStatus.active:
        return 'Activo';
      case LoanStatus.defaulted:
        return 'En mora';
      case LoanStatus.completed:
        return 'Completado';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(loanPaymentsProvider(loan.id));
    final paid = paymentsAsync.maybeWhen(
      data: (payments) => payments
          .where((p) =>
              p.status == PaymentStatus.paid ||
              p.status == PaymentStatus.early ||
              p.status == PaymentStatus.late)
          .length,
      orElse: () => 0,
    );

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoanDetailScreen(loan: loan),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
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
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currency.format(loan.totalAmount),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cuotas: $paid/${loan.totalPayments}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Fin: ${dateFormat.format(loan.endDate)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: loan.totalPayments > 0
                    ? paid / loan.totalPayments
                    : 0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
