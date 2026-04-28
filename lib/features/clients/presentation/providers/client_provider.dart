import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/datasources/client_remote_datasource.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/usecases/create_client_usecase.dart';
import '../../domain/usecases/get_clients_usecase.dart';
import '../../domain/usecases/toggle_client_status_usecase.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Datasource
final clientDataSourceProvider = Provider<ClientRemoteDataSource>((ref) {
  return ClientRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// Repository
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryImpl(ref.watch(clientDataSourceProvider));
});

// Usecases
final getClientsUseCaseProvider = Provider<GetClientsUseCase>((ref) {
  return GetClientsUseCase(ref.watch(clientRepositoryProvider));
});

final createClientUseCaseProvider = Provider<CreateClientUseCase>((ref) {
  return CreateClientUseCase(ref.watch(clientRepositoryProvider));
});

final toggleClientStatusUseCaseProvider =
    Provider<ToggleClientStatusUseCase>((ref) {
  return ToggleClientStatusUseCase(ref.watch(clientRepositoryProvider));
});

// Stream de clientes del admin actual
final clientsStreamProvider = StreamProvider<List<ClientEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(getClientsUseCaseProvider)(user.uid);
});

// State del notifier
class ClientState {
  final bool isLoading;
  final String? error;

  const ClientState({
    this.isLoading = false,
    this.error,
  });

  ClientState copyWith({bool? isLoading, String? error}) {
    return ClientState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier — Riverpod 2.x
class ClientNotifier extends Notifier<ClientState> {
  @override
  ClientState build() => const ClientState();

  Future<bool> createClient(CreateClientParams params) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(createClientUseCaseProvider)(params);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> toggleStatus(String clientId, bool currentStatus) async {
    try {
      await ref.read(toggleClientStatusUseCaseProvider)(
        clientId,
        !currentStatus,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final clientNotifierProvider =
    NotifierProvider<ClientNotifier, ClientState>(() => ClientNotifier());
