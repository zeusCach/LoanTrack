import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/loan_calculator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/loan_provider.dart';
import '../../domain/usecases/create_loan_usecase.dart';

class CreateLoanScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const CreateLoanScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends ConsumerState<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentsController = TextEditingController();
  final _interestController = TextEditingController();

  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  double _previewPayment = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _paymentsController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final payments = int.tryParse(_paymentsController.text) ?? 0;
    final interest = double.tryParse(_interestController.text) ?? 0;

    if (amount > 0 && payments > 0) {
      setState(() {
        _previewPayment = LoanCalculator.calculatePaymentAmount(
          totalAmount: amount,
          interestRate: interest,
          totalPayments: payments,
        );
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final adminId = ref.read(authStateProvider).value?.uid;
    if (adminId == null) return;

    final success = await ref.read(loanNotifierProvider.notifier).createLoan(
          CreateLoanParams(
            clientId: widget.clientId,
            adminId: adminId,
            totalAmount: double.parse(_amountController.text),
            totalPayments: int.parse(_paymentsController.text),
            interestRate: double.parse(_interestController.text.isEmpty
                ? '0'
                : _interestController.text),
            frequency: _frequency,
            startDate: _startDate,
          ),
          clientName: widget.clientName,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préstamo creado con cuotas generadas'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear préstamo'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loanNotifierProvider).isLoading;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Préstamo — ${widget.clientName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Monto
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto del préstamo',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updatePreview(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  if (double.parse(v) <= 0)
                    return 'El monto debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Número de cuotas
              TextFormField(
                controller: _paymentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de cuotas',
                  prefixIcon: Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updatePreview(),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Ingresa el número de cuotas';
                  if (int.tryParse(v) == null) return 'Número inválido';
                  if (int.parse(v) <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interés
              TextFormField(
                controller: _interestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interés % (opcional)',
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updatePreview(),
              ),
              const SizedBox(height: 16),

              // Frecuencia
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia de pago',
                  prefixIcon: Icon(Icons.calendar_month),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Quincenal')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                ],
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 16),

              // Fecha inicio
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.secondary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha de inicio',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          Text(dateFormat.format(_startDate),
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Preview cuota
              if (_previewPayment > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monto por cuota:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '\$${_previewPayment.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      : const Text('Crear Préstamo',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
