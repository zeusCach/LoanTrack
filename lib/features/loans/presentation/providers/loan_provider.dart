import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/services/local_notifications_service.dart';
import '../../../../core/utils/loan_calculator.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/loan_remote_datasource.dart';
import '../../data/repositories/loan_repository_impl.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loan_repository.dart';
import '../../domain/usecases/create_loan_usecase.dart';
import '../../domain/usecases/get_loans_usecase.dart';

final loanDataSourceProvider = Provider<LoanRemoteDataSource>((ref) {
  return LoanRemoteDataSourceImpl(firestore: ref.watch(firestoreProvider));
});

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepositoryImpl(ref.watch(loanDataSourceProvider));
});

final createLoanUseCaseProvider = Provider<CreateLoanUseCase>((ref) {
  return CreateLoanUseCase(ref.watch(loanRepositoryProvider));
});

final getLoansByClientUseCaseProvider =
    Provider<GetLoansByClientUseCase>((ref) {
  return GetLoansByClientUseCase(ref.watch(loanRepositoryProvider));
});

final getLoansByAdminUseCaseProvider = Provider<GetLoansByAdminUseCase>((ref) {
  return GetLoansByAdminUseCase(ref.watch(loanRepositoryProvider));
});

// Loans de un cliente específico
final clientLoansProvider = StreamProvider.family<List<LoanEntity>, String>(
  (ref, clientId) => ref.watch(getLoansByClientUseCaseProvider)(clientId),
);

// Todos los loans del admin
final adminLoansProvider = StreamProvider<List<LoanEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(getLoansByAdminUseCaseProvider)(user.uid);
});

// Notifier
class LoanNotifier extends StateNotifier<AsyncValue<void>> {
  final CreateLoanUseCase _createLoan;
  final LoanRepository _repository;
  final LocalNotificationsService _notifications;

  LoanNotifier({
    required CreateLoanUseCase createLoan,
    required LoanRepository repository,
    required LocalNotificationsService notifications,
  })  : _createLoan = createLoan,
        _repository = repository,
        _notifications = notifications,
        super(const AsyncValue.data(null));

  Future<bool> createLoan(CreateLoanParams params, {String? clientName}) async {
    state = const AsyncValue.loading();
    try {
      final loan = await _createLoan(params);

      await _notifications.showLoanCreated(
        loanId: loan.id,
        clientName: clientName ?? 'cliente',
        totalAmount: loan.totalAmount,
        totalPayments: params.totalPayments,
      );

      final frequency = LoanModelFrequencyMapper.fromString(params.frequency);
      final generatedPayments = LoanCalculator.generatePayments(
        loanId: loan.id,
        clientId: params.clientId,
        adminId: params.adminId,
        paymentAmount: loan.paymentAmount,
        totalPayments: params.totalPayments,
        frequency: frequency,
        startDate: params.startDate,
      );

      for (final payment in generatedPayments) {
        await _notifications.schedulePaymentDueReminder(
          loanId: loan.id,
          clientName: clientName ?? 'cliente',
          paymentNumber: payment.paymentNumber,
          expectedDate: payment.expectedDate,
          amount: payment.amount,
        );
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> updateStatus(String loanId, String status) async {
    try {
      await _repository.updateLoanStatus(loanId, status);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

class LoanModelFrequencyMapper {
  static LoanFrequency fromString(String frequency) {
    switch (frequency) {
      case 'weekly':
        return LoanFrequency.weekly;
      case 'biweekly':
        return LoanFrequency.biweekly;
      case 'monthly':
      default:
        return LoanFrequency.monthly;
    }
  }
}

final loanNotifierProvider =
    StateNotifierProvider<LoanNotifier, AsyncValue<void>>((ref) {
  return LoanNotifier(
    createLoan: ref.watch(createLoanUseCaseProvider),
    repository: ref.watch(loanRepositoryProvider),
    notifications: LocalNotificationsService.instance,
  );
});
