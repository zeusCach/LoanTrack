import '../repositories/client_repository.dart';

class ToggleClientStatusUseCase {
  final ClientRepository _repository;
  const ToggleClientStatusUseCase(this._repository);

  Future<void> call(String clientId, bool isActive) {
    return _repository.toggleClientStatus(clientId, isActive);
  }
}
