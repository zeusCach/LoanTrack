import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/register_payment_usecase.dart';
import '../providers/payment_provider.dart';

class RegisterPaymentScreen extends ConsumerStatefulWidget {
  final PaymentEntity payment;
  const RegisterPaymentScreen({super.key, required this.payment});

  @override
  ConsumerState<RegisterPaymentScreen> createState() =>
      _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends ConsumerState<RegisterPaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paidDate = DateTime.now();
  final _penaltyController = TextEditingController();
  final _penaltyReasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _penaltyController.dispose();
    _penaltyReasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _paidDate = picked);
  }

  Future<void> _submit() async {
    final success =
        await ref.read(paymentNotifierProvider.notifier).registerPayment(
              RegisterPaymentParams(
                paymentId: widget.payment.id,
                method: _method,
                paidDate: _paidDate,
                penaltyAmount: double.tryParse(_penaltyController.text) ?? 0,
                penaltyReason: _penaltyReasonController.text.trim(),
                notes: _notesController.text.trim(),
                expectedDate: widget.payment.expectedDate,
              ),
            );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Pago registrado' : 'Error al registrar'),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(paymentNotifierProvider).isLoading;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cuota #${widget.payment.paymentNumber}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(currency.format(widget.payment.amount),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
            Text(
              'Vencía: ${dateFormat.format(widget.payment.expectedDate)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Método de pago
            const Text('Método de pago',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _method = PaymentMethod.cash),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _method == PaymentMethod.cash
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _method == PaymentMethod.cash
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.payments_outlined,
                              color: _method == PaymentMethod.cash
                                  ? AppColors.primary
                                  : AppColors.secondary),
                          const SizedBox(height: 4),
                          Text('Efectivo',
                              style: TextStyle(
                                  color: _method == PaymentMethod.cash
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _method = PaymentMethod.transfer),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _method == PaymentMethod.transfer
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _method == PaymentMethod.transfer
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_outlined,
                              color: _method == PaymentMethod.transfer
                                  ? AppColors.primary
                                  : AppColors.secondary),
                          const SizedBox(height: 4),
                          Text('Transferencia',
                              style: TextStyle(
                                  color: _method == PaymentMethod.transfer
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fecha de pago
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fecha de pago',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        Text(dateFormat.format(_paidDate),
                            style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sanción (opcional)
            TextFormField(
              controller: _penaltyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto de sanción (opcional)',
                prefixIcon: Icon(Icons.warning_amber_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _penaltyReasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de sanción',
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar Pago',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
