import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/services/local_notifications_service.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/add_penalty_usecase.dart';
import '../../domain/usecases/get_payments_usecase.dart';
import '../../domain/usecases/register_payment_usecase.dart';

final localNotificationsServiceProvider = Provider<LocalNotificationsService>((ref) {
  return LocalNotificationsService.instance;
});

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

// Stream de pagos pendientes/atrasados del admin actual (para "Pagos del día").
// Una sola consulta a Firestore en lugar de N suscripciones por préstamo.
final dueAdminPaymentsProvider =
    StreamProvider<List<PaymentEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  final today = DateTime.now();
  final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

  return firestore
      .collection('payments')
      .where('adminId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .where('expectedDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
      .orderBy('expectedDate')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => PaymentModel.fromFirestore(d).toEntity()).toList());
});

// Notifier
class PaymentNotifier extends StateNotifier<AsyncValue<void>> {
  final RegisterPaymentUseCase _registerPayment;
  final AddPenaltyUseCase _addPenalty;
  final LocalNotificationsService _notifications;

  PaymentNotifier({
    required RegisterPaymentUseCase registerPayment,
    required AddPenaltyUseCase addPenalty,
    required LocalNotificationsService notifications,
  })  : _registerPayment = registerPayment,
        _addPenalty = addPenalty,
        _notifications = notifications,
        super(const AsyncValue.data(null));

  Future<bool> registerPayment(RegisterPaymentParams params) async {
    state = const AsyncValue.loading();
    try {
      await _registerPayment(params);
      await _notifications.showPaymentRegistered(
        paymentId: params.paymentId,
        paymentNumber: params.paymentNumber,
        amount: params.amount,
      );
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
      await _notifications.showPenaltyApplied(
        paymentId: params.paymentId,
        paymentNumber: params.paymentNumber,
        penaltyAmount: params.penaltyAmount,
      );
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
    notifications: ref.watch(localNotificationsServiceProvider),
  );
});
