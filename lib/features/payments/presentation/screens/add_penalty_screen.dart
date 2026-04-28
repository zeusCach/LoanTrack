import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/add_penalty_usecase.dart';
import '../providers/payment_provider.dart';

class AddPenaltyScreen extends ConsumerStatefulWidget {
  final PaymentEntity payment;
  const AddPenaltyScreen({super.key, required this.payment});

  @override
  ConsumerState<AddPenaltyScreen> createState() => _AddPenaltyScreenState();
}

class _AddPenaltyScreenState extends ConsumerState<AddPenaltyScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.payment.hasPenalty) {
      _amountController.text = widget.payment.penaltyAmount.toString();
      _reasonController.text = widget.payment.penaltyReason;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(paymentNotifierProvider.notifier)
        .addPenalty(AddPenaltyParams(
          paymentId: widget.payment.id,
          penaltyAmount: double.parse(_amountController.text),
          penaltyReason: _reasonController.text.trim(),
          paymentNumber: widget.payment.paymentNumber,
        ));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(success ? 'Sanción aplicada' : 'Error al aplicar sanción'),
        backgroundColor: success ? AppColors.warning : AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(paymentNotifierProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  'Sanción — Cuota #${widget.payment.paymentNumber}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto de sanción',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa el monto';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo de la sanción',
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Ingresa el motivo' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
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
                    : const Text('Aplicar Sanción',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
