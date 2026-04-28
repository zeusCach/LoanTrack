import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class GetClientsUseCase {
  final ClientRepository _repository;
  const GetClientsUseCase(this._repository);

  Stream<List<ClientEntity>> call(String adminId) {
    return _repository.getClients(adminId);
  }
}
