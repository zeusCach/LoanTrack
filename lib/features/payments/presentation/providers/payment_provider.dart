import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/add_penalty_usecase.dart';
import '../../domain/usecases/get_payments_usecase.dart';
import '../../domain/usecases/register_payment_usecase.dart';

// Datasource
final paymentDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(firestore: ref.watch(firestoreProvider));
});

// Repository
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(paymentDataSourceProvider));
});

// Usecases
final getPaymentsByLoanProvider = Provider<GetPaymentsByLoanUseCase>((ref) {
  return GetPaymentsByLoanUseCase(ref.watch(paymentRepositoryProvider));
});

final getPaymentsByClientProvider = Provider<GetPaymentsByClientUseCase>((ref) {
  return GetPaymentsByClientUseCase(ref.watch(paymentRepositoryProvider));
});

final registerPaymentUseCaseProvider = Provider<RegisterPaymentUseCase>((ref) {
  return RegisterPaymentUseCase(ref.watch(paymentRepositoryProvider));
});

final addPenaltyUseCaseProvider = Provider<AddPenaltyUseCase>((ref) {
  return AddPenaltyUseCase(ref.watch(paymentRepositoryProvider));
});

// Stream pagos por préstamo
final loanPaymentsProvider =
    StreamProvider.family<List<PaymentEntity>, String>((ref, loanId) {
  return ref.watch(getPaymentsByLoanProvider)(loanId);
});

// Stream pagos por cliente
final clientPaymentsProvider =
    StreamProvider.family<List<PaymentEntity>, String>((ref, clientId) {
  return ref.watch(getPaymentsByClientProvider)(clientId);
});

// Notifier
class PaymentNotifier extends StateNotifier<AsyncValue<void>> {
  final RegisterPaymentUseCase _registerPayment;
  final AddPenaltyUseCase _addPenalty;

  PaymentNotifier({
    required RegisterPaymentUseCase registerPayment,
    required AddPenaltyUseCase addPenalty,
  })  : _registerPayment = registerPayment,
        _addPenalty = addPenalty,
        super(const AsyncValue.data(null));

  Future<bool> registerPayment(RegisterPaymentParams params) async {
    state = const AsyncValue.loading();
    try {
      await _registerPayment(params);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> addPenalty(AddPenaltyParams params) async {
    state = const AsyncValue.loading();
    try {
      await _addPenalty(params);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<void>>((ref) {
  return PaymentNotifier(
    registerPayment: ref.watch(registerPaymentUseCaseProvider),
    addPenalty: ref.watch(addPenaltyUseCaseProvider),
  );
});
